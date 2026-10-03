import 'package:flutter/material.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Displays a single financial metric in a Paper Receipt Aesthetic card.
///
/// Used on the wallet dashboard to show Available Balance, Total Debt,
/// Base Capital, and Liquor Debt in a consistent, high-contrast paper ticket layout.
///
/// The [isHero] variant renders a larger amount number for the primary
/// balance indicator that the waiter needs to read at a glance under sunlight.
class FinancialMetricCard extends StatelessWidget {
  const FinancialMetricCard({
    super.key,
    required this.label,
    required this.amount,
    required this.accentColor,
    required this.icon,
    this.isHero = false,
    this.subtitle,
  });

  final String label;
  final int amount;
  final Color accentColor;
  final IconData icon;

  /// When true, renders a larger amount font (hero balance card).
  final bool isHero;

  /// Optional supporting text below the amount.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperSurface,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(
          color: AppColors.paperBorder,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.paperShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isHero ? AppDimensions.space20 : AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.space6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: AppDimensions.iconSm),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.statusBadge.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isHero ? AppDimensions.space12 : AppDimensions.space8),

          // ── Amount (mono — voz de tiquete para cifras) ─────────────────
          Text(
            amount.toCop,
            style: AppTextStyles.receiptTotal.copyWith(
              fontSize: isHero ? 28 : 20,
              color: accentColor,
            ),
          ),

          // ── Subtitle ────────────────────────────────────────────────
          if (subtitle != null) ...[
            const SizedBox(height: AppDimensions.space4),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact two-column row of metric cards. Used in the secondary metrics section.
class MetricCardRow extends StatelessWidget {
  const MetricCardRow({
    super.key,
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: AppDimensions.space12),
        Expanded(child: right),
      ],
    );
  }
}
