import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/finance/models/transaction_model.dart';
import '../theme/app_theme.dart';

class Fmt {
  static final NumberFormat money =
      NumberFormat.currency(symbol: 'Br ', decimalDigits: 2);
  static final NumberFormat money0 =
      NumberFormat.currency(symbol: 'Br ', decimalDigits: 0);
  static final NumberFormat compact = NumberFormat.compact();

  static String shortDate(DateTime d) => DateFormat('MMM d').format(d);

  static String dayHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(d);
  }

  static IconData categoryIcon(String category, bool isIncome) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Transport':
        return Icons.directions_car_outlined;
      case 'Software':
        return Icons.laptop_mac_outlined;
      case 'Utilities':
        return Icons.bolt_outlined;
      case 'Salary':
        return Icons.payments_outlined;
      case 'Freelance':
        return Icons.work_outline;
      case 'Entertainment':
        return Icons.movie_outlined;
      case 'Investment':
        return Icons.trending_up;
      case 'Shipment Income':
      case 'Shipment Expense':
        return Icons.local_shipping_outlined;
      default:
        return isIncome ? Icons.south_west : Icons.north_east;
    }
  }
}

/// White rounded card with a soft shadow. Optional tap and gradient.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppTheme.surfaceWhite) : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Small tinted label.
class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const Pill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onTap;

  const TransactionTile({super.key, required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type.toLowerCase() == 'income';
    final color = isIncome ? AppTheme.successGreen : AppTheme.dangerRed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Fmt.categoryIcon(tx.category, isIncome),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${tx.category} • ${Fmt.shortDate(tx.date)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (tx.shipmentNumber.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Pill(
                            label: tx.shipmentNumber,
                            color: AppTheme.primaryBlue,
                            icon: Icons.local_shipping_outlined,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIncome ? '+' : '-'}${Fmt.money.format(tx.amount)}',
              style: AppTheme.money.copyWith(color: color, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
