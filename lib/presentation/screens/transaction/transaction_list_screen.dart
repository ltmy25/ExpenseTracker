import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/receipt_ocr_service.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/transaction.dart';
import '../../providers/auth_providers.dart';
import '../../providers/category_providers.dart';
import '../../providers/transaction_providers.dart';
import 'widgets/add_transaction_bottom_sheet.dart';
import 'widgets/transaction_item.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  static const List<String> _ocrNoiseKeywords = [
    'hoa don',
    'thanh toan',
    'so hd',
    'ma hd',
    'tong tien',
    'thanh tien',
    'powered by',
    'ipos',
    'cash',
    'change',
  ];

  String _resolveCategoryName(List<Category> categories, String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return 'Danh mục không xác định';
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
      imageQuality: 100,
      maxWidth: 2400,
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
      final ocrResult = await service.extractDetailedFromImagePath(pickedFile.path);
      final items = ocrResult.items;

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (items.isEmpty) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không nhận diện được món/giá từ hóa đơn.'),
            action: SnackBarAction(
              label: 'Xem debug OCR',
              onPressed: () => _showOcrDebugDialog(context, ocrResult),
            ),
          ),
        );
        return;
      }

      if (!context.mounted) {
        return;
      }

      final selectedItems = await _reviewOcrItems(context, items);
      if (selectedItems == null) {
        return;
      }

      if (selectedItems.isEmpty) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa chọn dòng nào để tạo giao dịch.')),
        );
        return;
      }

      final categories = await ref.read(categoriesStreamProvider.future);
      Category? expenseCategory;
      for (final category in categories) {
        if (category.type == TransactionType.expense) {
          expenseCategory = category;
          break;
        }
      }

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
      for (final item in selectedItems) {
        final tx = Transaction(
          id: '',
          userId: user.uid,
          title: item.name,
          amount: item.amount,
          occurredAt: now,
          createdAt: now,
          updatedAt: now,
          categoryId: expenseCategory.id,
          type: TransactionType.expense,
          note: 'Tạo tự động từ OCR hóa đơn',
        );
        await ref.read(addTransactionUseCaseProvider).call(user.uid, tx);
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tạo ${selectedItems.length} giao dịch từ hóa đơn.')),
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

  Future<void> _showOcrDebugDialog(
    BuildContext context,
    ReceiptOcrExtractionResult result,
  ) async {
    final previewLines = result.sanitizedLines.take(80).toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Debug OCR'),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sanitized lines: ${result.sanitizedLines.length}'),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(dialogContext).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(previewLines.join('\n')),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: result.rawText));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Đã copy raw OCR text.')),
                  );
                }
              },
              child: const Text('Copy raw text'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<List<ReceiptOcrItem>?> _reviewOcrItems(
    BuildContext context,
    List<ReceiptOcrItem> items,
  ) async {
    final selected = items.map((item) => !_isLikelyNoiseItem(item)).toList();

    return showDialog<List<ReceiptOcrItem>>(
      context: context,
      builder: (dialogContext) {
        final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

        return StatefulBuilder(
          builder: (stateContext, setState) {
            final selectedCount = selected.where((v) => v).length;

            return AlertDialog(
              title: const Text('Xác nhận dòng OCR'),
              content: SizedBox(
                width: double.maxFinite,
                height: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đã nhận diện ${items.length} dòng. Chọn các dòng hợp lệ trước khi lưu.',
                      style: Theme.of(stateContext).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (itemContext, index) {
                          final item = items[index];
                          return CheckboxListTile(
                            dense: true,
                            value: selected[index],
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                selected[index] = value ?? false;
                              });
                            },
                            title: Text(item.name),
                            subtitle: Text(currency.format(item.amount)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (var i = 0; i < selected.length; i++) {
                        selected[i] = false;
                      }
                    });
                  },
                  child: const Text('Bỏ chọn hết'),
                ),
                FilledButton(
                  onPressed: () {
                    final result = <ReceiptOcrItem>[];
                    for (var i = 0; i < items.length; i++) {
                      if (selected[i]) {
                        result.add(items[i]);
                      }
                    }
                    Navigator.of(dialogContext).pop(result);
                  },
                  child: Text('Lưu ($selectedCount)'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isLikelyNoiseItem(ReceiptOcrItem item) {
    final name = _normalizeOcrText(item.name);
    if (name.length < 3) {
      return true;
    }

    if (item.amount < 100 || item.amount > 100000000) {
      return true;
    }

    for (final keyword in _ocrNoiseKeywords) {
      if (name.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  String _normalizeOcrText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
