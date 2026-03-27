import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../../domain/entities/category.dart';
import '../../../providers/transaction_providers.dart';
import '../../../providers/category_providers.dart';
import '../../../providers/auth_providers.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const AddTransactionBottomSheet({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends ConsumerState<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late TransactionType _selectedType;
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction?.title ?? '');
    _amountController = TextEditingController(
      text: widget.transaction?.amount != null ? widget.transaction!.amount.toInt().toString() : '',
    );
    _selectedDate = widget.transaction?.occurredAt ?? DateTime.now();
    _selectedType = widget.transaction?.type ?? TransactionType.expense;
    _selectedCategoryId = widget.transaction?.categoryId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(categoryControllerProvider.notifier).ensureDefaultCategories(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm danh mục mới'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Tên danh mục (ví dụ: Ăn trưa)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final user = ref.read(authStateProvider).value;
              if (user != null) {
                final newCategory = Category(
                  id: '',
                  userId: user.uid,
                  name: nameController.text,
                  icon: 'category',
                  color: '#FF9E9E9E',
                  type: _selectedType,
                  isDefault: false,
                );
                await ref.read(addCategoryUseCaseProvider).call(user.uid, newCategory);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một danh mục')),
      );
      return;
    }

    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final transaction = Transaction(
        id: widget.transaction?.id ?? '',
        userId: userId,
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        occurredAt: _selectedDate,
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        categoryId: _selectedCategoryId!,
        type: _selectedType,
      );

      if (widget.transaction == null) {
        await ref.read(addTransactionUseCaseProvider).call(userId, transaction);
      } else {
        await ref.read(updateTransactionUseCaseProvider).call(userId, transaction);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.transaction == null ? 'Thêm giao dịch' : 'Sửa giao dịch',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Chi phí'), icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(value: TransactionType.income, label: Text('Thu nhập'), icon: Icon(Icons.add_circle_outline)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _selectedCategoryId = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền',
                      border: OutlineInputBorder(),
                      prefixText: '₫ ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {}); // Để cập nhật thanh gợi ý khi gõ
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập số tiền';
                      if (double.tryParse(value) == null) return 'Số tiền không hợp lệ';
                      return null;
                    },
                  ),
                  if (_amountController.text.isNotEmpty && double.tryParse(_amountController.text) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _quickAmountChip(1000),
                          _quickAmountChip(10000),
                          _quickAmountChip(100000),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: categoriesAsync.when(
                      data: (categories) {
                        final filteredCategories = categories.where((cat) => cat.type == _selectedType).toList();
                        if (_selectedCategoryId != null && !filteredCategories.any((cat) => cat.id == _selectedCategoryId)) {
                          _selectedCategoryId = null;
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Danh mục',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: filteredCategories.map((cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name)
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedCategoryId = value),
                          validator: (value) => value == null ? 'Chọn danh mục' : null,
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Lỗi tải danh mục'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Thêm danh mục mới',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Ngày giao dịch'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Lưu giao dịch'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAmountChip(int multiplier) {
    final currentAmount = double.tryParse(_amountController.text) ?? 0;
    final suggestedAmount = (currentAmount * multiplier).toInt();
    final formatter = NumberFormat.compact(locale: 'vi_VN');

    return ActionChip(
      avatar: const Icon(Icons.auto_awesome, size: 14),
      label: Text('x${multiplier == 1000 ? 'k' : formatter.format(multiplier)} (${formatter.format(suggestedAmount)})'),
      onPressed: () {
        setState(() {
          _amountController.text = suggestedAmount.toString();
        });
      },
    );
  }
}
