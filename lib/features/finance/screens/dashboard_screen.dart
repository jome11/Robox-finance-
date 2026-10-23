import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import 'add_edit_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'analytics_screen.dart';
import 'shipments_screen.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Robox Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_shipping_outlined),
            tooltip: 'Shipment Transactions',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShipmentsScreen()),
              );
            },
          ),
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
                        Text(
                          currencyFormat.format(provider.netBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'JetBrainsMono',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem(
                              'Income',
                              currencyFormat.format(provider.totalIncome),
                              Colors.white,
                              Icons.arrow_downward,
                            ),
                            Container(width: 1, height: 40, color: Colors.white24),
                            _buildSummaryItem(
                              'Expenses',
                              currencyFormat.format(provider.totalExpenses),
                              Colors.white,
                              Icons.arrow_upward,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Shipment Quick Access Card
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShipmentsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
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
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
                            child: const Icon(Icons.local_shipping, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Shipment Transactions',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'View transactions grouped by shipment ID',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryBlue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                                    Expanded(child: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    if (tx.shipmentNumber.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tx.shipmentNumber,
                                          style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text('${tx.category} • ${DateFormat('MMM dd, yyyy').format(tx.date)}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                      style: TextStyle(
                                        color: isIncome ? AppTheme.successGreen : AppTheme.dangerRed,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'JetBrainsMono',
                                      ),
                                    ),
                                    if (tx.imagePaths.isNotEmpty) ...[
                                      const SizedBox(width: 8),
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
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              amount,
              style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono'),
            ),
          ],
        ),
      ],
    );
  }
}
