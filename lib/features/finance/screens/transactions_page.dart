import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/stat_tile.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import 'transaction_detail_screen.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const _filters = ['All', 'Income', 'Expenses', 'Shipments'];

  final TextEditingController _search = TextEditingController();
  String _filter = 'All';
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<TransactionModel> _apply(List<TransactionModel> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((t) {
      final isIncome = t.type.toLowerCase() == 'income';
      switch (_filter) {
        case 'Income':
          if (!isIncome) return false;
          break;
        case 'Expenses':
          if (isIncome) return false;
          break;
        case 'Shipments':
          if (t.shipmentNumber.trim().isEmpty) return false;
          break;
      }
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          t.subcategory.toLowerCase().contains(q) ||
          t.shipmentNumber.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<bool> _confirmDelete(TransactionModel tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('"${tx.title}" will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final items = _apply(finance.transactions);

    double income = 0;
    double expense = 0;
    for (final t in items) {
      if (t.type.toLowerCase() == 'income') {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    final groups = <DateTime, List<TransactionModel>>{};
    for (final t in items) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      groups.putIfAbsent(key, () => []).add(t);
    }

    final children = <Widget>[];
    if (items.isNotEmpty) {
      children.add(
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Income',
                value: income,
                color: StatTile.income,
                icon: Icons.south_west,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Expenses',
                value: expense,
                color: StatTile.expense,
                icon: Icons.north_east,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Net',
                value: income - expense,
                color: StatTile.net,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
          ],
        ),
      );
    }
    groups.forEach((day, txs) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8, left: 4),
          child: Text(
            Fmt.dayHeader(day),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      );
      children.add(
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < txs.length; i++) ...[
                if (i > 0) const Divider(),
                Dismissible(
                  key: ValueKey(txs[i].id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppTheme.dangerRed.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.dangerRed,
                    ),
                  ),
                  confirmDismiss: (_) async {
                    if (await _confirmDelete(txs[i]) && mounted) {
                      await context
                          .read<FinanceProvider>()
                          .deleteTransaction(txs[i].id);
                    }
                    return false; // the list rebuilds from the provider
                  },
                  child: TransactionTile(
                    tx: txs[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TransactionDetailScreen(transaction: txs[i]),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${items.length} records',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search title, category, shipment...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in _filters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: _filter == f,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _filter == f
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textMuted,
                            ),
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => finance.loadTransactions(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                children: items.isEmpty
                    ? [
                        EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: _query.isEmpty
                              ? 'No transactions here'
                              : 'No matches',
                          message: _query.isEmpty
                              ? 'Tap Add transaction to create one.'
                              : 'Try a different search or filter.',
                        ),
                      ]
                    : children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
