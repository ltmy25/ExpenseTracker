import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/receipt_ocr_service.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/transaction.dart';
import '../../providers/auth_providers.dart';
import '../../providers/category_providers.dart';
import '../../providers/chat_providers.dart';
import '../../providers/transaction_providers.dart';
import 'widgets/add_transaction_bottom_sheet.dart';
import 'widgets/transaction_item.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  static const Map<String, List<String>> _categoryKeywordGroups = {
    'an uong': ['an', 'uong', 'food', 'am thuc', 'do an', 'cafe', 'ca phe', 'tra sua', 'nha hang'],
    'di chuyen': ['di chuyen', 'xang', 'grab', 'taxi', 'xe', 'gui xe', 'bus', 'metro'],
    'mua sam': ['mua sam', 'shopping', 'sieu thi', 'mini mart', 'store', 'tap hoa', 'shop'],
    'hoa don': ['hoa don', 'dien', 'nuoc', 'internet', 'wifi', 'dien thoai', 'phi dich vu'],
    'suc khoe': ['suc khoe', 'benh vien', 'thuoc', 'y te', 'phong kham', 'nhathuoc'],
    'giao duc': ['giao duc', 'hoc phi', 'khoa hoc', 'sach', 'education', 'lop hoc'],
  };

  String _resolveCategoryName(List<Category> categories, String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return 'Danh mục không xác định';
  }

  Category? _pickBestExpenseCategory(List<Category> categories, String hintText) {
    final expenseCategories = categories.where((c) => c.type == TransactionType.expense).toList();
    if (expenseCategories.isEmpty) {
      return null;
    }

    final normalizedHint = _normalizeText(hintText);
    if (normalizedHint.isEmpty) {
      return expenseCategories.first;
    }

    Category? best;
    var bestScore = -1;

    for (final category in expenseCategories) {
      final categoryNorm = _normalizeText(category.name);
      var score = 0;

      if (categoryNorm.isNotEmpty && normalizedHint.contains(categoryNorm)) {
        score += 10;
      }
      if (categoryNorm.isNotEmpty && categoryNorm.contains(normalizedHint)) {
        score += 6;
      }

      final words = categoryNorm.split(' ').where((w) => w.length >= 3);
      for (final word in words) {
        if (normalizedHint.contains(word)) {
          score += 2;
        }
      }

      for (final group in _categoryKeywordGroups.entries) {
        if (!normalizedHint.contains(group.key)) {
          continue;
        }
        for (final keyword in group.value) {
          final normalizedKeyword = _normalizeText(keyword);
          if (categoryNorm.contains(normalizedKeyword)) {
            score += 3;
            break;
          }
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = category;
      }
    }

    return best ?? expenseCategories.first;
  }

  String _normalizeText(String input) {
    var text = input.toLowerCase();
    const withAccent = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const withoutAccent = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyyd';
    for (var i = 0; i < withAccent.length; i++) {
      text = text.replaceAll(withAccent[i], withoutAccent[i]);
    }
    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionBottomSheet(),
    );
  }

  void _showEditTransaction(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionBottomSheet(transaction: transaction),
    );
  }

  void _showTransactionDetail(
    BuildContext context,
    Transaction transaction,
    String categoryName,
  ) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final date = DateFormat('dd/MM/yyyy').format(transaction.occurredAt);
    final isIncome = transaction.type == TransactionType.income;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chi tiết giao dịch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Tiêu đề', transaction.title),
              _detailRow('Số tiền', '${isIncome ? '+' : '-'}${currency.format(transaction.amount)}'),
              _detailRow('Loại', isIncome ? 'Thu nhập' : 'Chi phí'),
              _detailRow('Ngày', date),
              _detailRow('Danh mục', categoryName),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Đóng'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showEditTransaction(context, transaction);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Chỉnh sửa'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Future<ImageSource?> _pickReceiptImageSource(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp hóa đơn'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanReceiptAndCreateExpenses(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để tạo giao dịch.')),
      );
      return;
    }

    final imageSource = await _pickReceiptImageSource(context);
    if (imageSource == null) {
      return;
    }

    final pickedFile = await ImagePicker().pickImage(
      source: imageSource,
      imageQuality: 85,
      maxWidth: 1800,
    );

    if (pickedFile == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = ReceiptOcrService();
      final ocrText = await service.extractTextFromImagePath(pickedFile.path);
      final aiResult = await ref.read(generateAiReceiptTextAnalysisUseCaseProvider).call(
            ocrText: ocrText,
            financialContext: 'Nguoi dung dang tao giao dich tu OCR hoa don.',
          );

      var totalAmount = aiResult.totalAmount ?? 0;
      if (totalAmount <= 0 && aiResult.items.isNotEmpty) {
        for (final item in aiResult.items) {
          totalAmount += item.amount;
        }
      }
      if (totalAmount <= 0) {
        totalAmount = await service.extractTotalFromImagePath(pickedFile.path) ?? 0;
      }

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (totalAmount <= 0) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không nhận diện được tổng tiền từ hóa đơn.')),
        );
        return;
      }

      final categories = await ref.read(categoriesStreamProvider.future);
      final hintSegments = <String>[
        aiResult.categoryHint ?? '',
        aiResult.reply,
        ...aiResult.items.take(3).map((e) => e.name),
      ];
      final expenseCategory = _pickBestExpenseCategory(categories, hintSegments.join(' '));

      if (expenseCategory == null) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy danh mục chi phí để gán giao dịch.')),
        );
        return;
      }

      final now = DateTime.now();
      final tx = Transaction(
        id: '',
        userId: user.uid,
        title: 'Chi tiêu từ hóa đơn',
        amount: totalAmount,
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        categoryId: expenseCategory.id,
        type: TransactionType.expense,
        note: 'Tạo tự động từ OCR + AI phân tích hóa đơn',
      );
      await ref.read(addTransactionUseCaseProvider).call(user.uid, tx);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tạo giao dịch từ tổng tiền hóa đơn: ${totalAmount.toStringAsFixed(0)}đ.')),
      );
    } catch (error) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR thất bại: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Giao dịch',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.2,
            fontSize: 20,
            shadows: [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        centerTitle: false,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF74C69D),
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x26000000),
        elevation: 2,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF52B788), Color(0xFF40916C), Color(0xFF2D6A4F)],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _scanReceiptAndCreateExpenses(context, ref),
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: 'OCR hóa đơn (camera/thư viện)',
          ),
          IconButton(
            onPressed: () {
              // Navigation to Category management could go here
            },
            icon: const Icon(Icons.category_outlined),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: colors.outline),
                  const SizedBox(height: 16),
                  const Text('Chưa có giao dịch nào'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final categories = categoriesAsync.valueOrNull ?? const [];
              final categoryName = _resolveCategoryName(categories, transaction.categoryId);

              return TransactionItem(
                transaction: transaction,
                onTap: () => _showTransactionDetail(context, transaction, categoryName),
                onEdit: () => _showEditTransaction(context, transaction),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Lỗi: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
