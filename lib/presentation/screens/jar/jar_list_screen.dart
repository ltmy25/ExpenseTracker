import 'package:expensetracker/domain/entities/transaction.dart' as entity;
import 'package:expensetracker/presentation/providers/jar_providers.dart';
import 'package:expensetracker/presentation/providers/transaction_providers.dart';
import 'package:expensetracker/presentation/screens/jar/add_jar_screen.dart';
import 'package:expensetracker/presentation/screens/jar/jar_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class JarListScreen extends ConsumerWidget {
  const JarListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jarsAsync = ref.watch(jarsStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hũ chi tiêu'),
      ),
      body: jarsAsync.when(
        data: (jars) => transactionsAsync.when(
          data: (transactions) => jars.isEmpty
              ? const Center(child: Text('Chưa có hũ nào. Hãy tạo hũ đầu tiên!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jars.length,
                  itemBuilder: (context, index) {
                    final jar = jars[index];
                    
                    // Lọc giao dịch thuộc hũ này (qua jarId hoặc qua danh mục liên kết)
                    final jarTxs = transactions.where((tx) {
                      final matchJarId = tx.jarId == jar.id;
                      final matchCategory = jar.categoryIds?.contains(tx.categoryId) ?? false;
                      return matchJarId || matchCategory;
                    }).toList();

                    // Tính toán tổng thu và tổng chi thực tế
                    double totalExpense = 0;
                    double totalIncome = 0;
                    for (final tx in jarTxs) {
                      if (tx.type == entity.TransactionType.expense) {
                        totalExpense += tx.amount;
                      } else if (tx.type == entity.TransactionType.income) {
                        totalIncome += tx.amount;
                      } else if (tx.type == entity.TransactionType.transfer) {
                        if (tx.jarId == jar.id) totalExpense += tx.amount;
                        if (tx.toJarId == jar.id) totalIncome += tx.amount;
                      }
                    }

                    final double budget = jar.budgetLimit ?? 0;
                    // SỐ DƯ = NGÂN SÁCH - CHI + THU (Theo yêu cầu của bạn)
                    final double remaining = budget - totalExpense + totalIncome;
                    // % ĐÃ DÙNG = CHI / NGÂN SÁCH
                    final double percentUsed = budget > 0 ? (totalExpense / budget).clamp(0.0, 1.2) : 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => JarDetailScreen(jar: jar)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _getPercentColor(percentUsed).withOpacity(0.1),
                                    child: Icon(_getIconData(jar.icon), color: _getPercentColor(percentUsed)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          jar.name,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Còn lại: ${currencyFormat.format(remaining)}',
                                          style: TextStyle(
                                            color: remaining < 0 ? Colors.red : Colors.green[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => AddJarScreen(jar: jar)),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Đã chi: ${currencyFormat.format(totalExpense)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text('${(percentUsed * 100).toStringAsFixed(0)}%', 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: _getPercentColor(percentUsed))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: percentUsed > 1.0 ? 1.0 : percentUsed,
                                  backgroundColor: Colors.grey[100],
                                  valueColor: AlwaysStoppedAnimation<Color>(_getPercentColor(percentUsed)),
                                  minHeight: 10,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Ngân sách: ${currencyFormat.format(budget)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  if (percentUsed >= 1.0)
                                    const Text('Vượt hạn mức!', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Lỗi tải giao dịch: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải hũ: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddJarScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'shopping': return Icons.shopping_bag_outlined;
      case 'food': return Icons.restaurant;
      case 'transport': return Icons.directions_bus_outlined;
      default: return Icons.account_balance_wallet_outlined;
    }
  }

  Color _getPercentColor(double percent) {
    if (percent >= 1.0) return Colors.red;        // Quá mức
    if (percent >= 0.8) return Colors.orange;     // Sắp hết
    if (percent >= 0.5) return Colors.amber;      // Đã tiêu một nửa
    return Colors.green;                          // An toàn
  }
}
