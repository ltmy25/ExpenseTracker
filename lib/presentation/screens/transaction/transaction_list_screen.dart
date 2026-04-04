import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/transaction.dart';
import '../../providers/category_providers.dart';
import '../../providers/transaction_providers.dart';
import 'widgets/add_transaction_bottom_sheet.dart';
import 'widgets/transaction_item.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

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
