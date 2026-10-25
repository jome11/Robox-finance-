import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/attachment_widgets.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import 'add_edit_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('It will be marked as deleted and can be restored later.'),
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

    if (confirm == true && context.mounted) {
      await Provider.of<FinanceProvider>(context, listen: false)
          .deleteTransaction(transaction.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type.toLowerCase() == 'income';
    final color = isIncome ? AppTheme.successGreen : AppTheme.dangerRed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTransactionScreen(transaction: transaction),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed),
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Fmt.categoryIcon(transaction.category, isIncome),
                    color: color,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  transaction.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${isIncome ? '+' : '-'}${Fmt.money.format(transaction.amount)}',
                    style: AppTheme.money.copyWith(fontSize: 32, color: color),
                  ),
                ),
                if (transaction.shipmentNumber.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Pill(
                    label: transaction.shipmentNumber,
                    color: AppTheme.primaryBlue,
                    icon: Icons.local_shipping_outlined,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _row('Type', isIncome ? 'Income' : 'Expense'),
                const Divider(),
                _row('Category', transaction.category),
                const Divider(),
                _row(
                  'Subcategory',
                  transaction.subcategory.isEmpty ? 'N/A' : transaction.subcategory,
                ),
                const Divider(),
                _row('Payment method', transaction.paymentMethod),
                const Divider(),
                _row(
                  'Date',
                  DateFormat('MMM d, yyyy • HH:mm').format(transaction.date),
                ),
                if (transaction.note.isNotEmpty) ...[
                  const Divider(),
                  _row('Note', transaction.note),
                ],
              ],
            ),
          ),
          if (transaction.imagePaths.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeader(title: 'Photos'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final ref in transaction.imagePaths)
                  GestureDetector(
                    onTap: () => showAttachmentViewer(context, ref),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AttachmentImage(reference: ref, size: 110),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
