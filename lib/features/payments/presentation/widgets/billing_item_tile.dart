import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../domain/entities/billing_selection.dart';

/// A single row in the [BillingScreen] item list.
///
/// States:
///   • Selectable  — [!item.isPaid && !item.isCancelled]. Checkbox active.
///   • Locked-paid — [item.isPaid]. Checkbox disabled (shown as checked + lock).
///   • Cancelled   — [item.isCancelled]. Shown at reduced opacity; no checkbox.
///
/// [onToggle] is invoked only for selectable items.
class BillingItemTile extends StatelessWidget {
  const BillingItemTile({
    super.key,
    required this.item,
    required this.selection,
    required this.onToggle,
    required this.onSetQuantity,
  });

  final OrderItemEntity item;
  final BillingSelection selection;
  final VoidCallback onToggle;

  /// Sets how many units of this line to pay now (for partial / per-unit
  /// payment of lines with quantity > 1).
  final void Function(int qty) onSetQuantity;

  bool get _isSelectable => !item.isPaid && !item.isCancelled;
  bool get _isSelected => selection.isSelected(item.id);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double opacity = item.isCancelled ? 0.4 : (item.isPaid ? 0.65 : 1.0);

    final borderColor = item.isPaid
        ? AppColors.statusGreen.withOpacity(0.45)
        : _isSelected
            ? AppColors.brand.withOpacity(0.7)
            : item.isLiquor
                ? AppColors.statusPurple.withOpacity(0.35)
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline);

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: _isSelectable
            ? () {
                HapticFeedback.selectionClick();
                onToggle();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: AppDimensions.space8),
          decoration: BoxDecoration(
            color: _isSelected
                ? AppColors.brand.withOpacity(0.08)
                : item.isPaid
                    ? AppColors.statusGreen.withOpacity(0.06)
                    : isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: borderColor,
              width: _isSelected ? 2.0 : AppDimensions.cardBorderWidth,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Urgency/category stripe ───────────────────────────────
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: item.isPaid
                        ? AppColors.statusGreen
                        : item.categoryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppDimensions.radiusMd),
                      bottomLeft: Radius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                ),

                // ── Checkbox ─────────────────────────────────────────────
                SizedBox(
                  width: AppDimensions.tapTargetMin,
                  child: Center(
                    child: _buildCheckbox(context),
                  ),
                ),

                // ── Product info ──────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.space12,
                      horizontal: AppDimensions.space4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.quantity > 1
                              ? '${item.productName}  ×${item.quantity}'
                              : item.productName,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurface
                                : AppColors.lightOnSurface,
                            decoration: item.isCancelled
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppColors.statusRed,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimensions.space4),
                        Row(
                          children: [
                            _StatusChip(item: item),
                            if (item.isLiquor) ...[
                              const SizedBox(width: AppDimensions.space6),
                              _LiquorBadge(),
                            ],
                          ],
                        ),

                        // ── Per-unit payment stepper ────────────────────────
                        // For lines with more than one unit, let the waiter pay
                        // only some of them (e.g. 4 beers shared, paid one by
                        // one). Hidden for single-unit and already-paid lines.
                        if (_isSelectable && item.quantity > 1) ...[
                          const SizedBox(height: AppDimensions.space8),
                          _UnitStepper(
                            selected: selection.quantityOf(item.id),
                            total: item.quantity,
                            unitPrice: item.price,
                            onChanged: onSetQuantity,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Line total ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(
                    right: AppDimensions.space16,
                    top: AppDimensions.space12,
                    bottom: AppDimensions.space12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.lineTotal.toCop,
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: item.isPaid
                              ? AppColors.statusGreen
                              : item.categoryColor,
                          decoration: item.isCancelled
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      if (item.quantity > 1)
                        Text(
                          '${item.price.toCop} c/u',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkDisabled
                                : AppColors.lightDisabled,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    if (item.isCancelled) {
      return const SizedBox.shrink();
    }

    if (item.isPaid) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Checkbox(
            value: true,
            onChanged: null, // locked
            fillColor: WidgetStateProperty.all(AppColors.statusGreen),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: const BoxDecoration(
                color: AppColors.statusGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return Checkbox(
      value: _isSelected,
      onChanged: (_) {
        HapticFeedback.selectionClick();
        onToggle();
      },
      activeColor: AppColors.brand,
      checkColor: const Color(0xFF1A0A00),
    );
  }
}

// ── Per-unit payment stepper ────────────────────────────────────────────────────

class _UnitStepper extends StatelessWidget {
  const _UnitStepper({
    required this.selected,
    required this.total,
    required this.unitPrice,
    required this.onChanged,
  });

  /// Units currently selected to pay (0 = none).
  final int selected;
  final int total;
  final int unitPrice;
  final void Function(int qty) onChanged;

  @override
  Widget build(BuildContext context) {
    final active = selected > 0;
    final color = active ? AppColors.brand : AppColors.darkOnSurfaceVariant;

    return Row(
      children: [
        Text(
          'Pagar:',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.darkOnSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppDimensions.space8),
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                color: color,
                onTap: selected > 0 ? () => onChanged(selected - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$selected de $total',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                color: color,
                onTap: selected < total ? () => onChanged(selected + 1) : null,
              ),
            ],
          ),
        ),
        if (active) ...[
          const SizedBox(width: AppDimensions.space8),
          Flexible(
            child: Text(
              (unitPrice * selected).toCop,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? color : AppColors.darkDisabled,
        ),
      ),
    );
  }
}

// ── Status chip ────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.item});

  final OrderItemEntity item;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (item.status) {
      OrderItemStatus.pending =>
        ('PENDIENTE', AppColors.statusOrange, Icons.access_time_rounded),
      OrderItemStatus.delivered when item.isPaid =>
        ('PAGADO', AppColors.statusGreen, Icons.check_circle_rounded),
      OrderItemStatus.delivered =>
        ('ENTREGADO', AppColors.statusBlue, Icons.check_rounded),
      OrderItemStatus.cancelled =>
        ('CANCELADO', AppColors.statusRed, Icons.cancel_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.statusBadge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _LiquorBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statusPurple.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.statusPurple.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wine_bar_rounded,
            size: 11,
            color: AppColors.statusPurple,
          ),
          const SizedBox(width: 4),
          Text(
            'LICOR',
            style: AppTextStyles.statusBadge.copyWith(
              color: AppColors.statusPurple,
            ),
          ),
        ],
      ),
    );
  }
}
