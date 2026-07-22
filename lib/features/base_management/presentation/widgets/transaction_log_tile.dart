import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/base_transaction_entity.dart';

/// Renders a single [BaseTransactionEntity] in the wallet's transaction history.
///
/// Designed for quick visual scanning:
///   • Left accent stripe uses the transaction type color.
///   • Icon + label identify the type at a glance.
///   • Right side shows the COP amount and exact timestamp.
class TransactionLogTile extends StatelessWidget {
  const TransactionLogTile({
    super.key,
    required this.transaction,
    this.showDivider = true,
  });

  final BaseTransactionEntity transaction;
  final bool showDivider;

  static final _timeFormat = DateFormat('hh:mm a', 'es_CO');
  static final _dateFormat = DateFormat('dd MMM', 'es_CO');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = transaction.displayColor;
    final now = DateTime.now();
    final isToday = _isSameDay(transaction.timestamp, now);

    final timeLabel = isToday
        ? _timeFormat.format(transaction.timestamp)
        : '${_dateFormat.format(transaction.timestamp)} · ${_timeFormat.format(transaction.timestamp)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bounded-height row (no IntrinsicHeight — it can produce runaway
        // heights under the unbounded constraints a SliverList hands each item).
        Container(
          // Left accent stripe drawn as a border so the row needs no intrinsic
          // height resolution.
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accentColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.only(left: AppDimensions.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon ─────────────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  transaction.displayIcon,
                  color: accentColor,
                  size: AppDimensions.iconSm,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),

              // ── Label + timestamp ────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      transaction.displayLabel,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurface
                            : AppColors.lightOnSurface,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.lightOnSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeLabel,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (transaction.note != null) ...[
                      const SizedBox(height: AppDimensions.space2),
                      Text(
                        transaction.note!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkDisabled
                              : AppColors.lightDisabled,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Amount ───────────────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${transaction.displayPrefix}${transaction.amount.toCop}',
                    style: AppTextStyles.receiptTotal.copyWith(
                      fontSize: 15,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space2),
                  _TypeBadge(type: transaction.type),
                ],
              ),
              const SizedBox(width: AppDimensions.space4),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: AppDimensions.space24,
            thickness: AppDimensions.dividerThickness,
            indent: 52,
            color: isDark
                ? AppColors.darkOutlineVariant
                : AppColors.lightOutlineVariant,
          ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Private badge widget ───────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      TransactionType.initial => ('INICIO', AppColors.statusGreen),
      TransactionType.increase => ('AUMENTO', AppColors.brand),
      TransactionType.decrease => ('BAJA', AppColors.statusOrange),
      TransactionType.liquorAdjustment => ('LICOR', AppColors.statusPurple),
      TransactionType.liquorSettlement => ('BOTELLA', AppColors.statusGreen),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.badgePaddingH,
        vertical: AppDimensions.badgePaddingV,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.statusBadge.copyWith(color: color),
      ),
    );
  }
}
