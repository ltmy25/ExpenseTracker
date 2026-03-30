import 'package:expensetracker/domain/entities/jar.dart';
import 'package:expensetracker/domain/entities/transaction.dart' as entity;
import 'package:expensetracker/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class JarDetailScreen extends ConsumerStatefulWidget {
  final Jar jar;
  const JarDetailScreen({super.key, required this.jar});

  @override
  ConsumerState<JarDetailScreen> createState() => _JarDetailScreenState();
}

class _JarDetailScreenState extends ConsumerState<JarDetailScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jar.name),
      ),
      body: Column(
        children: [
          // Bộ lọc ngày
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Từ ngày', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(dateFormat.format(_startDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Đến ngày', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(dateFormat.format(_endDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Danh sách giao dịch liên quan
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                // Lọc giao dịch theo categoryIds của hũ và theo khoảng ngày
                final filtered = transactions.where((tx) {
                  final inDateRange = tx.occurredAt.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
                      tx.occurredAt.isBefore(_endDate.add(const Duration(days: 1)));
                  
                  // Giao dịch thuộc hũ này nếu nó có categoryId nằm trong list categoryIds của hũ
                  final matchCategory = widget.jar.categoryIds?.contains(tx.categoryId) ?? false;
                  
                  return inDateRange && matchCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Không có giao dịch nào trong khoảng thời gian này.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    final isExpense = tx.type == entity.TransactionType.expense;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        child: Icon(
                          isExpense ? Icons.remove : Icons.add,
                          color: isExpense ? Colors.red : Colors.green,
                        ),
                      ),
                      title: Text(tx.title ?? 'Không có tiêu đề'),
                      subtitle: Text(dateFormat.format(tx.occurredAt)),
                      trailing: Text(
                        '${isExpense ? '-' : '+'}${currencyFormat.format(tx.amount)}',
                        style: TextStyle(
                          color: isExpense ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
}
