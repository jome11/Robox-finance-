import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import 'add_edit_transaction_screen.dart';
import '../../../core/theme/app_theme.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  void _showFullScreenImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.file(File(path)),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'Br ', decimalDigits: 2);
    final isIncome = transaction.type.toLowerCase() == 'income';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditTransactionScreen(transaction: transaction),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppTheme.dangerRed),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Transaction'),
                  content: const Text('Are you sure you want to delete this transaction?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: AppTheme.dangerRed)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await Provider.of<FinanceProvider>(context, listen: false).deleteTransaction(transaction.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isIncome ? AppTheme.successGreen.withOpacity(0.15) : AppTheme.dangerRed.withOpacity(0.15),
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? AppTheme.successGreen : AppTheme.dangerRed,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(transaction.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? AppTheme.successGreen : AppTheme.dangerRed,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow('Category', transaction.category),
                  const Divider(height: 24),
                  _buildDetailRow('Subcategory', transaction.subcategory.isEmpty ? 'N/A' : transaction.subcategory),
                  const Divider(height: 24),
                  _buildDetailRow('Payment Method', transaction.paymentMethod),
                  if (transaction.shipmentNumber.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow('Shipment Number', transaction.shipmentNumber),
                  ],
                  const Divider(height: 24),
                  _buildDetailRow('Date', DateFormat('yyyy-MM-dd HH:mm').format(transaction.date)),
                  if (transaction.note.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow('Note', transaction.note),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (transaction.imagePaths.isNotEmpty) ...[
            const Text('Attachments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: transaction.imagePaths.length,
                itemBuilder: (context, index) {
                  final path = transaction.imagePaths.isNotEmpty ? transaction.imagePaths[index] : '';
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(context, path),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
