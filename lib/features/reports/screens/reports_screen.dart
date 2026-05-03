import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_card.dart';
import 'package:my_app/core/services/firestore_service.dart';
import 'package:my_app/core/services/auth_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final String uid = _authService.currentUserId ?? "";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Business Insights", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Report Period",
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      helpText: "Select Month",
                    );
                    if (picked != null) {
                      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
                    }
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getSalesStream(uid),
              builder: (context, salesSnapshot) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getExpensesStream(uid),
                  builder: (context, expenseSnapshot) {
                    if (salesSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allSales = salesSnapshot.data ?? [];
                    final allExpenses = expenseSnapshot.data ?? [];
                    
                    // Filter monthly sales
                    final monthSales = allSales.where((sale) {
                      final saleDate = DateTime.parse(sale['createdAt']);
                      return saleDate.year == _selectedMonth.year && saleDate.month == _selectedMonth.month;
                    }).toList();

                    // Filter monthly expenses
                    final monthExpenses = allExpenses.where((exp) {
                      final expDate = DateTime.parse(exp['date']);
                      return expDate.year == _selectedMonth.year && expDate.month == _selectedMonth.month;
                    }).toList();

                    // Calculations
                    double totalEarnings = 0;
                    double totalProfit = 0;
                    double totalTax = 0;
                    int billCount = monthSales.length;
                    Map<String, int> itemQuantities = {};
                    List<double> dailySales = List.filled(31, 0.0);
                    
                    for (var sale in monthSales) {
                      final amount = (sale['totalAmount'] ?? 0.0);
                      totalEarnings += amount;
                      totalProfit += (sale['totalProfit'] ?? 0.0);
                      totalTax += (sale['totalTax'] ?? 0.0);
                      final items = sale['items'] as List;
                      for (var item in items) {
                        final name = item['name'];
                        final qty = item['qty'] as int;
                        itemQuantities[name] = (itemQuantities[name] ?? 0) + qty;
                      }

                      final saleDate = DateTime.parse(sale['createdAt']);
                      dailySales[saleDate.day - 1] += amount;
                    }

                    final double expensesTotal = monthExpenses.fold(0.0, (sum, exp) => sum + (exp['amount'] ?? 0.0));
                    final double netProfit = totalProfit - expensesTotal;
                    final double avgBill = billCount > 0 ? totalEarnings / billCount : 0;

                    // Sort top items
                    final sortedItems = itemQuantities.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Net Profit Highlight
                          CustomCard(
                            padding: const EdgeInsets.all(20),
                            color: Colors.white,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1.5),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (netProfit >= 0 ? const Color(0xFF16A085) : Colors.red).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    netProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, 
                                    color: netProfit >= 0 ? const Color(0xFF16A085) : Colors.red, 
                                    size: 28
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Net Profit (Take Home)", style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
                                    Text(
                                      "₹${netProfit.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        fontSize: 24, 
                                        fontWeight: FontWeight.w900, 
                                        color: netProfit >= 0 ? AppColors.textPrimary : Colors.red
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Monthly Summary Card
                          CustomCard(
                            color: AppColors.primary,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Total Sales (Revenue)", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                          Text(
                                            "₹${totalEarnings.toStringAsFixed(0)}",
                                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white24, height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSummaryStat("Gross Profit", "₹${totalProfit.toStringAsFixed(0)}"),
                                    _buildSummaryStat("Expenses", "₹${expensesTotal.toStringAsFixed(0)}"),
                                    _buildSummaryStat("Avg Bill", "₹${avgBill.toStringAsFixed(0)}"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sales Daily Chart
                          const Text(
                            "Sales Trends",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          CustomCard(
                            padding: const EdgeInsets.all(16),
                            child: _buildBarChart(dailySales),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            "Top Selling Items",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),

                          // Top Items List
                          if (sortedItems.isEmpty)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("No items sold this month yet", style: TextStyle(color: AppColors.textSecondary)),
                            ))
                          else
                            ...sortedItems.take(5).map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: CustomCard(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${entry.value} Sold",
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )).toList(),
                        ],
                      ),
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<double> dailySales) {
    List<BarChartGroupData> barGroups = [];
    double maxY = 0;
    for (int i = 0; i < dailySales.length; i++) {
      if (dailySales[i] > maxY) maxY = dailySales[i];
      barGroups.add(
        BarChartGroupData(
          x: i + 1,
          barRods: [
            BarChartRodData(
              toY: dailySales[i],
              color: AppColors.primary,
              width: 6,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY > 0 ? maxY : 100,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
      );
    }

    if (maxY == 0) maxY = 100;

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 5 == 0 || value == 1) { 
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                       _compactCurrency(value), 
                       style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                       textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true, 
            drawVerticalLine: false,
            horizontalInterval: (maxY * 1.2) / 4,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'Day ${group.x}\n₹${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _compactCurrency(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
