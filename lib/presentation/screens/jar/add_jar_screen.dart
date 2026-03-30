import 'package:expensetracker/domain/entities/jar.dart';
import 'package:expensetracker/presentation/providers/category_providers.dart';
import 'package:expensetracker/presentation/providers/jar_providers.dart';
import 'package:expensetracker/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _fmt = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final num? value = num.tryParse(digits);
    if (value == null) return oldValue;
    final formatted = _fmt.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddJarScreen extends ConsumerStatefulWidget {
  final Jar? jar;
  const AddJarScreen({super.key, this.jar});

  @override
  ConsumerState<AddJarScreen> createState() => _AddJarScreenState();
}

class _AddJarScreenState extends ConsumerState<AddJarScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _budgetController;
  
  final Set<String> _selectedCategoryIds = {};
  String _selectedColor = '#2196F3';
  String _selectedIcon = 'account_balance_wallet';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.jar?.name ?? '');
    final fmt = NumberFormat.decimalPattern('vi_VN');
    _budgetController = TextEditingController(
      text: widget.jar?.budgetLimit != null ? fmt.format(widget.jar!.budgetLimit) : '',
    );

    if (widget.jar?.categoryIds != null) {
      _selectedCategoryIds.addAll(widget.jar!.categoryIds!);
    }
    if (widget.jar?.color != null) _selectedColor = widget.jar!.color!;
    if (widget.jar?.icon != null) _selectedIcon = widget.jar!.icon!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final isEditing = widget.jar != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa hũ' : 'Tạo ngân sách hũ'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hũ chi tiêu',
                  hintText: 'Ví dụ: Ăn uống, Di chuyển...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tên hũ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Ngân sách định mức',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Vui lòng nhập ngân sách';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text('Danh mục áp dụng cho hũ này:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Các giao dịch thuộc danh mục này sẽ tự động trừ vào hũ.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (categories) => Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.where((c) => c.type.name == 'expense').map((cat) {
                      final selected = _selectedCategoryIds.contains(cat.id);
                      return FilterChip(
                        label: Text(cat.name),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) _selectedCategoryIds.add(cat.id); else _selectedCategoryIds.remove(cat.id);
                        }),
                      );
                    }).toList(),
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Không thể tải danh mục'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEditing ? 'CẬP NHẬT THAY ĐỔI' : 'TẠO HŨ CHI TIÊU',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hũ?'),
        content: const Text('Dữ liệu hũ sẽ bị xóa, nhưng các giao dịch vẫn sẽ được giữ lại.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('HỦY')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('XÓA', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(jarControllerProvider).deleteJar(widget.jar!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final double newBudget = double.tryParse(_budgetController.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
      double newBalance;

      if (widget.jar != null) {
        // Nếu đang sửa: Cập nhật số dư dựa trên sự thay đổi ngân sách
        final double budgetDiff = newBudget - (widget.jar!.budgetLimit ?? 0);
        newBalance = widget.jar!.currentBalance + budgetDiff;
      } else {
        // Nếu tạo mới: Số dư ban đầu = Ngân sách
        newBalance = newBudget;
      }
      
      final jar = Jar(
        id: widget.jar?.id ?? '',
        name: _nameController.text,
        currentBalance: newBalance,
        budgetLimit: newBudget,
        categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds.toList(),
        color: _selectedColor,
        icon: _selectedIcon,
        createdAt: widget.jar?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (widget.jar != null) {
          await ref.read(jarControllerProvider).updateJar(jar);
        } else {
          await ref.read(jarControllerProvider).createJar(jar);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
        }
      }
    }
  }
}
