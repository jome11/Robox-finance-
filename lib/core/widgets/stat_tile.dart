import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

/// Solid coloured tile for Income / Expenses / Net figures.
class StatTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  /// Preset colours so every screen uses the same ones.
  static const Color income = AppTheme.successGreen;
  static const Color expense = AppTheme.dangerRed;
  static const Color net = AppTheme.primaryBlue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.2)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.money0.format(value),
              style: AppTheme.money.copyWith(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
