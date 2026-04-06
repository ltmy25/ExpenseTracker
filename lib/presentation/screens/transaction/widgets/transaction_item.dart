import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../providers/transaction_providers.dart';
import '../../../providers/auth_providers.dart';

class TransactionItem extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        final userId = ref.read(authStateProvider).value?.uid;
        if (userId != null) {
          ref.read(deleteTransactionUseCaseProvider).call(userId, transaction.id);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: transaction.type == TransactionType.income 
                ? Colors.green.withValues(alpha: 0.1) 
                : Colors.red.withValues(alpha: 0.1),
            child: Icon(
              transaction.type == TransactionType.income 
                  ? Icons.arrow_downward 
                  : Icons.arrow_upward,
              color: transaction.type == TransactionType.income ? Colors.green : Colors.red,
            ),
          ),
          title: Text(transaction.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(dateFormat.format(transaction.occurredAt)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${transaction.type == TransactionType.income ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transaction.type == TransactionType.income ? Colors.green : Colors.red,
                ),
              ),
              IconButton(
                tooltip: 'Chỉnh sửa giao dịch',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: Colors.blueGrey,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
