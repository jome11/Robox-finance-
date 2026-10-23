import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import 'transaction_detail_screen.dart';
import '../../../core/theme/app_theme.dart';

class ShipmentsScreen extends StatelessWidget {
  const ShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: 'Br ', decimalDigits: 2);
    final shipmentsMap = provider.shipmentsMap;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment Transactions'),
      ),
      body: shipmentsMap.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  const Text('No shipment transactions found', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Add a shipment number when creating transactions', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: shipmentsMap.entries.map((entry) {
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shipment Header
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, color: AppTheme.primaryBlue, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Shipment ID: $shipmentId',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: sNet >= 0 ? AppTheme.successGreen.withOpacity(0.15) : AppTheme.dangerRed.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currencyFormat.format(sNet),
                                style: TextStyle(
                                  color: sNet >= 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Income: ${currencyFormat.format(sIncome)}', style: const TextStyle(color: AppTheme.successGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('Expenses: ${currencyFormat.format(sExpense)}', style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('Count: ${txs.length}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                        const Divider(height: 20),
                        // Ordered List of Transactions for this Shipment ID
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: txs.length,
                          itemBuilder: (context, i) {
                            final tx = txs[i];
                            final isIncome = tx.type.toLowerCase() == 'income';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransactionDetailScreen(transaction: tx),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: isIncome ? AppTheme.successGreen.withOpacity(0.15) : AppTheme.dangerRed.withOpacity(0.15),
                                child: Icon(
                                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isIncome ? AppTheme.successGreen : AppTheme.dangerRed,
                                  size: 16,
                                ),
                              ),
                              title: Text(tx.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              subtitle: Text('${tx.category} • ${DateFormat('MMM dd, yyyy').format(tx.date)}',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              trailing: Text(
                                '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                style: TextStyle(
                                  color: isIncome ? AppTheme.successGreen : AppTheme.dangerRed,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 13,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
