import 'package:expensetracker/domain/entities/transaction.dart' as entity;
import 'package:expensetracker/presentation/providers/transaction_providers.dart';
import 'package:expensetracker/presentation/providers/category_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum FilterType { day, month, year, all, custom }

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  FilterType _filterType = FilterType.year;
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExpenseMode = true;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Trang chủ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
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
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final filteredTxs = _filterTransactions(transactions);
          
          double totalIncome = 0;
          double totalExpense = 0;
          Map<String, double> categoryMap = {};

          for (final tx in filteredTxs) {
            if (tx.type == entity.TransactionType.income) {
              totalIncome += tx.amount;
            } else if (tx.type == entity.TransactionType.expense) {
              totalExpense += tx.amount;
            }
            
            if (_isExpenseMode && tx.type == entity.TransactionType.expense) {
              categoryMap[tx.categoryId] = (categoryMap[tx.categoryId] ?? 0) + tx.amount;
            } else if (!_isExpenseMode && tx.type == entity.TransactionType.income) {
              categoryMap[tx.categoryId] = (categoryMap[tx.categoryId] ?? 0) + tx.amount;
            }
          }

          final netChange = totalIncome - totalExpense;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterHeader(),
                const SizedBox(height: 20),
                _buildSummaryCard(totalIncome, totalExpense, netChange, currencyFormat),
                const SizedBox(height: 24),
                _buildModeToggle(),
                const SizedBox(height: 20),
                _buildChartSection(categoryMap, categoriesAsync),
                const SizedBox(height: 24),
                _buildCategoryList(categoryMap, categoriesAsync, _isExpenseMode ? totalExpense : totalIncome, currencyFormat),
                
                if (_filterType == FilterType.year) ...[
                  const SizedBox(height: 32),
                  const Text('Xu hướng chi tiêu trong năm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildLineChart(filteredTxs),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Widget _buildFilterHeader() {
    String dateLabel = '';
    switch (_filterType) {
      case FilterType.day: dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate); break;
      case FilterType.month: dateLabel = 'Tháng ${_selectedDate.month}/${_selectedDate.year}'; break;
      case FilterType.year: dateLabel = 'Năm ${_selectedDate.year}'; break;
      case FilterType.all: dateLabel = 'Tất cả thời gian'; break;
      case FilterType.custom: 
        if (_startDate != null && _endDate != null) {
          dateLabel = '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}';
        } else {
          dateLabel = 'Chọn khoảng ngày';
        }
        break;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
            child: DropdownButton<FilterType>(
              value: _filterType,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: FilterType.day, child: Text('Ngày')),
                DropdownMenuItem(value: FilterType.month, child: Text('Tháng')),
                DropdownMenuItem(value: FilterType.year, child: Text('Năm')),
                DropdownMenuItem(value: FilterType.all, child: Text('Mọi lúc')),
                DropdownMenuItem(value: FilterType.custom, child: Text('Tùy chỉnh')),
              ],
              onChanged: (v) {
                setState(() {
                  _filterType = v!;
                  if (v == FilterType.custom) _pickDateRange();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          if (_filterType != FilterType.all)
            InkWell(
              onTap: _filterType == FilterType.custom ? _pickDateRange : _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
                child: Row(
                  children: [
                    Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_month, size: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<entity.Transaction> txs) {
    Map<int, double> monthlyData = {};
    for (int i = 1; i <= 12; i++) {
      monthlyData[i] = 0;
    }

    for (final tx in txs) {
      if (tx.type == entity.TransactionType.expense) {
        monthlyData[tx.occurredAt.month] = (monthlyData[tx.occurredAt.month] ?? 0) + tx.amount;
      }
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10),
      child: LineChart(
        LineChartData(
          minY: 0, // Đảm bảo biểu đồ không bị vẽ âm xuống dưới
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  if (val < 1 || val > 12) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('T${val.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                },
                interval: 1,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: monthlyData.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              preventCurveOverShooting: true, // CHỐNG LÕM/VƯỢT NGƯỠNG
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true), // Hiện chấm để dễ nhìn
              belowBarData: BarAreaData(
                show: true, 
                color: Colors.green.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double income, double expense, double net, NumberFormat fmt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal[50]!, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thay đổi ròng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(fmt.format(net), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('Chi phí', expense, Colors.red, Icons.arrow_downward, fmt)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryItem('Thu nhập', income, Colors.teal, Icons.arrow_upward, fmt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, IconData icon, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(child: Text(fmt.format(amount), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleBtn('Chi phí', _isExpenseMode, () => setState(() => _isExpenseMode = true)),
            _toggleBtn('Thu nhập', !_isExpenseMode, () => setState(() => _isExpenseMode = false)),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(color: active ? Colors.teal : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChartSection(Map<String, double> data, AsyncValue categories) {
    if (data.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('Không có dữ liệu')));
    
    return Container(
      height: 250,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          sections: data.entries.map((e) {
            final cat = (categories.value as List?)?.where((c) => c.id == e.key).firstOrNull;
            return PieChartSectionData(
              color: cat?.color != null ? Color(int.parse(cat!.color!.replaceAll('#', '0xFF'))) : Colors.blue,
              value: e.value,
              title: '',
              radius: 40,
              badgeWidget: _buildChartBadge(cat?.icon),
              badgePositionPercentageOffset: 1.1,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChartBadge(String? icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Icon(_getIconData(icon), size: 16),
    );
  }

  Widget _buildCategoryList(Map<String, double> data, AsyncValue categories, double total, NumberFormat fmt) {
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: sorted.map((e) {
        final cat = (categories.value as List?)?.where((c) => c.id == e.key).firstOrNull;
        final percent = total > 0 ? (e.value / total) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: Colors.grey[100], child: Icon(_getIconData(cat?.icon), color: Colors.black87)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat?.name ?? 'Khác', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(fmt.format(e.value), style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: percent, backgroundColor: Colors.grey[100], color: Colors.teal, minHeight: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('${(percent * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<entity.Transaction> _filterTransactions(List<entity.Transaction> txs) {
    return txs.where((tx) {
      switch (_filterType) {
        case FilterType.day:
          return tx.occurredAt.day == _selectedDate.day && tx.occurredAt.month == _selectedDate.month && tx.occurredAt.year == _selectedDate.year;
        case FilterType.month:
          return tx.occurredAt.month == _selectedDate.month && tx.occurredAt.year == _selectedDate.year;
        case FilterType.year:
          return tx.occurredAt.year == _selectedDate.year;
        case FilterType.all:
          return true;
        case FilterType.custom:
          if (_startDate == null || _endDate == null) return true;
          return tx.occurredAt.isAfter(_startDate!.subtract(const Duration(seconds: 1))) && 
                 tx.occurredAt.isBefore(_endDate!.add(const Duration(days: 1)));
      }
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'shopping': return Icons.shopping_bag;
      case 'food': return Icons.restaurant;
      case 'transport': return Icons.directions_bus;
      default: return Icons.category;
    }
  }
}
