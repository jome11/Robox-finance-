import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../finance/models/transaction_model.dart';
import '../../finance/providers/finance_provider.dart';
import '../../finance/screens/add_shipment_transaction_screen.dart';
import '../../finance/screens/shipments_screen.dart';
import '../../finance/screens/transaction_detail_screen.dart';
import '../../tasks/providers/tasks_provider.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _palette = [
  Color(0xFF1D4ED8),
  Color(0xFF7DD3FC),
  Color(0xFF1E3A8A),
  Color(0xFF60A5FA),
  Color(0xFF0EA5E9),
  Color(0xFFBFDBFE),
  Color(0xFF94A3B8),
];

class _Bucket {
  final String label;
  double income = 0;
  double expense = 0;
  _Bucket(this.label);
}

bool _inPeriod(DateTime d, String period, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  switch (period) {
    case 'Week':
      final diff = today.difference(day).inDays;
      return diff >= 0 && diff < 7;
    case 'Month':
      return d.year == now.year && d.month == now.month;
    default:
      return d.year == now.year;
  }
}

List<_Bucket> _buildBuckets(
  List<TransactionModel> txs,
  String period,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  late final List<_Bucket> buckets;
  late final int Function(DateTime) indexFor;

  if (period == 'Week') {
    buckets = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return _Bucket(_weekdays[day.weekday - 1]);
    });
    indexFor = (d) {
      final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
      return 6 - diff;
    };
  } else if (period == 'Month') {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final weeks = ((daysInMonth - 1) ~/ 7) + 1;
    buckets = List.generate(weeks, (i) => _Bucket('W${i + 1}'));
    indexFor = (d) => (d.day - 1) ~/ 7;
  } else {
    buckets = List.generate(12, (i) => _Bucket(_months[i]));
    indexFor = (d) => d.month - 1;
  }

  for (final t in txs) {
    final i = indexFor(t.date);
    if (i < 0 || i >= buckets.length) continue;
    if (t.type.toLowerCase() == 'income') {
      buckets[i].income += t.amount;
    } else {
      buckets[i].expense += t.amount;
    }
  }
  return buckets;
}

List<MapEntry<String, double>> _slices(Map<String, double> byCategory) {
  final entries = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (entries.length <= 6) return entries;
  final top = entries.take(5).toList();
  final rest = entries.skip(5).fold<double>(0, (sum, e) => sum + e.value);
  return [...top, MapEntry('Other', rest)];
}

class DashboardPage extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const DashboardPage({super.key, required this.onNavigate});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final tasks = context.watch<TasksProvider>();
    final auth = context.watch<AuthProvider>();
    final now = DateTime.now();
    final period = finance.selectedPeriod;

    if (finance.isLoading && finance.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final periodTxs = finance.transactions
        .where((t) => _inPeriod(t.date, period, now))
        .toList();
    double pIncome = 0;
    double pExpense = 0;
    final byCategory = <String, double>{};
    for (final t in periodTxs) {
      if (t.type.toLowerCase() == 'income') {
        pIncome += t.amount;
      } else {
        pExpense += t.amount;
        byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      }
    }
    final buckets = _buildBuckets(periodTxs, period, now);
    final slices = _slices(byCategory);
    final recent = [...finance.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final shipments = finance.shipmentsMap;
    final openTasks = tasks.openTasks;

    final username = auth.user?.username ?? 'Welcome';
    final initial = username.isEmpty ? '?' : username.substring(0, 1).toUpperCase();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([finance.loadTransactions(), tasks.load()]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            // ---------- Header ----------
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) async {
                    if (value == 'export') {
                      final result = await finance.exportToExcel();
                      if (context.mounted && result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result)),
                        );
                      }
                    } else if (value == 'logout') {
                      auth.logout();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(Icons.download_outlined),
                        title: Text('Export to Excel'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(Icons.logout, color: AppTheme.dangerRed),
                        title: Text('Sign out'),
                      ),
                    ),
                  ],
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ---------- Hero balance ----------
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total balance',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Fmt.money.format(finance.netBalance),
                      style: AppTheme.money.copyWith(
                        color: Colors.white,
                        fontSize: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStat(
                          label: 'Income',
                          value: finance.totalIncome,
                          icon: Icons.south_west,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeroStat(
                          label: 'Expenses',
                          value: finance.totalExpenses,
                          icon: Icons.north_east,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ---------- Period + coloured stats ----------
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'Week', label: Text('Week')),
                  ButtonSegment(value: 'Month', label: Text('Month')),
                  ButtonSegment(value: 'Year', label: Text('Year')),
                ],
                selected: {period},
                onSelectionChanged: (v) => finance.setPeriod(v.first),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Income',
                    value: pIncome,
                    color: StatTile.income,
                    icon: Icons.south_west,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Expenses',
                    value: pExpense,
                    color: StatTile.expense,
                    icon: Icons.north_east,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Net',
                    value: pIncome - pExpense,
                    color: StatTile.net,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---------- Cash flow chart ----------
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Cash flow',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _LegendDot(color: AppTheme.successGreen, label: 'Income'),
                      SizedBox(width: 12),
                      _LegendDot(color: AppTheme.dangerRed, label: 'Expenses'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: periodTxs.isEmpty
                        ? const Center(
                            child: Text(
                              'No activity in this period',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        : _CashFlowChart(buckets: buckets),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- Spending by category ----------
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Where your money goes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  if (slices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No expenses in this period',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 40,
                                  borderData: FlBorderData(show: false),
                                  sections: [
                                    for (var i = 0; i < slices.length; i++)
                                      PieChartSectionData(
                                        color: _palette[i % _palette.length],
                                        value: slices[i].value,
                                        title: '',
                                        radius: 16,
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Spent',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    Fmt.compact.format(pExpense),
                                    style: AppTheme.money.copyWith(fontSize: 15),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              for (var i = 0; i < slices.length; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _palette[i % _palette.length],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          slices[i].key,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        '${(pExpense > 0 ? slices[i].value / pExpense * 100 : 0).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- Shipments ----------
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shipments',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${shipments.length} tracked',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ShipmentsScreen(),
                          ),
                        ),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Income',
                          value: finance.shipmentIncome,
                          color: StatTile.income,
                          icon: Icons.south_west,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          label: 'Expenses',
                          value: finance.shipmentExpenses,
                          color: StatTile.expense,
                          icon: Icons.north_east,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          label: 'Net',
                          value: finance.shipmentNetBalance,
                          color: StatTile.net,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddShipmentTransactionScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add shipment transaction'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- Tasks ----------
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tasks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigate(2),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Pill(
                        label: '${openTasks.length} open',
                        color: AppTheme.primaryBlue,
                      ),
                      if (tasks.overdueCount > 0)
                        Pill(
                          label: '${tasks.overdueCount} overdue',
                          color: AppTheme.dangerRed,
                          icon: Icons.warning_amber_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (tasks.error != null && tasks.tasks.isEmpty)
                    const Text(
                      'Could not load tasks. Pull down to retry.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    )
                  else if (openTasks.isEmpty)
                    const Text(
                      'Nothing pending. Nice work.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    )
                  else
                    for (final task in openTasks.take(3))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: task.priority == 'high'
                                    ? AppTheme.dangerRed
                                    : task.priority == 'medium'
                                        ? AppTheme.warning
                                        : AppTheme.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (task.dueDate != null)
                              Text(
                                Fmt.shortDate(task.dueDate!),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: task.isOverdue
                                      ? AppTheme.dangerRed
                                      : AppTheme.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- Recent activity ----------
            SectionHeader(
              title: 'Recent activity',
              actionLabel: 'See all',
              onAction: () => onNavigate(1),
            ),
            const SizedBox(height: 4),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: recent.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions yet',
                      message: 'Tap Quick add to record your first one.',
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < recent.take(5).length; i++) ...[
                          if (i > 0) const Divider(),
                          TransactionTile(
                            tx: recent[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailScreen(
                                  transaction: recent[i],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Fmt.money0.format(value),
                    style: AppTheme.money.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _CashFlowChart extends StatelessWidget {
  final List<_Bucket> buckets;

  const _CashFlowChart({required this.buckets});

  @override
  Widget build(BuildContext context) {
    double maxValue = 0;
    for (final b in buckets) {
      maxValue = math.max(maxValue, math.max(b.income, b.expense));
    }
    final maxY = maxValue == 0 ? 100.0 : maxValue * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppTheme.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) => Text(
                Fmt.compact.format(value),
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    buckets[i].label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < buckets.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: buckets[i].income,
                  color: AppTheme.successGreen,
                  width: 7,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: buckets[i].expense,
                  color: AppTheme.dangerRed,
                  width: 7,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
