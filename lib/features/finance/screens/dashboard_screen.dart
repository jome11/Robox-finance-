import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'add_edit_transaction_screen.dart';
import 'add_shipment_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'analytics_screen.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinanceProvider>(context, listen: false).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: 'Br ', decimalDigits: 2);
    final shipmentsMap = provider.shipmentsMap;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Robox Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Analytics & Charts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export to Excel',
            onPressed: () async {
              final result = await provider.exportToExcel();
              if (mounted && result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result), backgroundColor: AppTheme.successGreen),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : RefreshIndicator(
              color: AppTheme.primaryBlue,
              backgroundColor: Colors.white,
              onRefresh: () => provider.loadTransactions(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Overall Balance & Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryBlue,
                          AppTheme.accentBlue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            currencyFormat.format(provider.netBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrainsMono',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryItem(
                                'Income',
                                currencyFormat.format(provider.totalIncome),
                                Colors.white,
                                Icons.arrow_downward,
                              ),
                            ),
                            Container(width: 1, height: 40, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 8)),
                            Expanded(
                              child: _buildSummaryItem(
                                'Expenses',
                                currencyFormat.format(provider.totalExpenses),
                                Colors.white,
                                Icons.arrow_upward,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dedicated Shipment Entry & Finances Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, color: AppTheme.primaryBlue, size: 22),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Shipment Finances & Income',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currencyFormat.format(provider.shipmentNetBalance),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: provider.shipmentNetBalance >= 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                                  fontFamily: 'JetBrainsMono',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Dedicated Add Shipment Transaction Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddShipmentTransactionScreen()),
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Add Shipment Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('Shipment Income', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      currencyFormat.format(provider.shipmentIncome),
                                      style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 30, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('Shipment Expenses', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      currencyFormat.format(provider.shipmentExpenses),
                                      style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (shipmentsMap.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Shipments List (Grouped by ID)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                          const SizedBox(height: 8),
                          ...shipmentsMap.entries.map((entry) {
                            final shipmentId = entry.key;
                            final txs = entry.value;
                            double sIncome = 0;
                            double sExpense = 0;
                            for (var t in txs) {
                              if (t.type.toLowerCase() == 'income') {
                                sIncome += t.amount;
                              } else {
                                sExpense += t.amount;
                              }
                            }
                            final sNet = sIncome - sExpense;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text('ID: $shipmentId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                      const SizedBox(width: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          currencyFormat.format(sNet),
                                          style: TextStyle(
                                            color: sNet >= 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            fontFamily: 'JetBrainsMono',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...txs.map((tx) {
                                    final isInc = tx.type.toLowerCase() == 'income';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => TransactionDetailScreen(transaction: tx),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              isInc ? Icons.arrow_downward : Icons.arrow_upward,
                                              size: 14,
                                              color: isInc ? AppTheme.successGreen : AppTheme.dangerRed,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(child: Text(tx.title, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                            const SizedBox(width: 8),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '${isInc ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isInc ? AppTheme.successGreen : AppTheme.dangerRed,
                                                  fontFamily: 'JetBrainsMono',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Transactions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                          );
                        },
                        icon: const Icon(Icons.pie_chart_outline, size: 18, color: AppTheme.primaryBlue),
                        label: const Text('View Analytics', style: TextStyle(color: AppTheme.primaryBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  provider.transactions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              const Text('No transactions yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                              const SizedBox(height: 8),
                              const Text('Tap + to add your first transaction', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = provider.transactions[index];
                            final isIncome = tx.type.toLowerCase() == 'income';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TransactionDetailScreen(transaction: tx),
                                    ),
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundColor: isIncome
                                      ? AppTheme.successGreen.withOpacity(0.15)
                                      : AppTheme.dangerRed.withOpacity(0.15),
                                  child: Icon(
                                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isIncome ? AppTheme.successGreen : AppTheme.dangerRed,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                                    if (tx.shipmentNumber.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tx.shipmentNumber,
                                          style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text('${tx.category} • ${DateFormat('MMM dd, yyyy').format(tx.date)}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                        style: TextStyle(
                                          color: isIncome ? AppTheme.successGreen : AppTheme.dangerRed,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'JetBrainsMono',
                                        ),
                                      ),
                                    ),
                                    if (tx.imagePaths.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.attach_file, size: 16, color: AppTheme.primaryBlue),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white24,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
