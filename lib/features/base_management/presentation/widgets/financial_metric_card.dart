import 'package:flutter/material.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Displays a single financial metric in a high-contrast card.
///
/// Used on the wallet dashboard to show Available Balance, Total Debt,
/// Base Capital, and Liquor Debt in a consistent, scannable layout.
///
/// The [isHero] variant renders a larger amount number for the primary
/// balance indicator that the waiter needs to read at a glance.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
    final borderColor =
        isDark ? AppColors.darkOutline : AppColors.lightOutline;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
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
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, color: accentColor, size: AppDimensions.iconSm),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.statusBadge.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isHero ? AppDimensions.space12 : AppDimensions.space8),

          // ── Amount ──────────────────────────────────────────────────
          Text(
            amount.toCop,
            style: (isHero ? AppTextStyles.displayMedium : AppTextStyles.displaySmall)
                .copyWith(color: accentColor),
          ),

          // ── Subtitle ────────────────────────────────────────────────
          if (subtitle != null) ...[
            const SizedBox(height: AppDimensions.space4),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
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
