import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: 'Br ', decimalDigits: 2);
    final chartData = provider.getGroupedChartData();
    final expensesByCategory = provider.getExpensesByCategory();

    final List<Color> categoryColors = [
      AppTheme.primaryBlue,
      AppTheme.successGreen,
      AppTheme.accentBlue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.amber,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Week', label: Text('Week')),
              ButtonSegment(value: 'Month', label: Text('Month')),
              ButtonSegment(value: 'Year', label: Text('Year')),
            ],
            selected: {provider.selectedPeriod},
            onSelectionChanged: (val) {
              provider.setPeriod(val.first);
            },
          ),
          const SizedBox(height: 24),
          const Text('Spending Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: chartData.isEmpty
                ? const Center(
                    child: Text('No data for selected period', style: TextStyle(color: AppTheme.textMuted)),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartData.values.isEmpty
                          ? 100
                          : (chartData.values.reduce((a, b) => a > b ? a : b) * 1.2),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final keys = chartData.keys.toList();
                              if (value.toInt() >= 0 && value.toInt() < keys.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    keys[value.toInt()],
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                'Br${value.toInt()}',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.textMuted.withOpacity(0.15),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: chartData.entries.map((entry) {
                        final index = chartData.keys.toList().indexOf(entry.key);
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value,
                              color: AppTheme.primaryBlue,
                              width: 16,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 32),
          const Text('Expenses by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: expensesByCategory.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('No expense data available', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 65,
                                sections: expensesByCategory.entries.map((entry) {
                                  final index = expensesByCategory.keys.toList().indexOf(entry.key);
                                  final color = categoryColors[index % categoryColors.length];
                                  final total = expensesByCategory.values.fold(0.0, (a, b) => a + b);
                                  final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;

                                  return PieChartSectionData(
                                    color: color,
                                    value: entry.value,
                                    title: '${percentage.toStringAsFixed(0)}%',
                                    radius: 35,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Total', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                Text(
                                  currencyFormat.format(provider.totalExpenses),
                                  style: const TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'JetBrainsMono',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: expensesByCategory.entries.map((entry) {
                          final index = expensesByCategory.keys.toList().indexOf(entry.key);
                          final color = categoryColors[index % categoryColors.length];
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('${entry.key}: ${currencyFormat.format(entry.value)}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
