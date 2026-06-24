import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/order_item_entity.dart';

/// Displays one [OrderItemEntity] inside the [TableOrderScreen] item list.
///
/// Visual states:
///   • Pending   → normal text, pending status chip.
///   • Delivered → slightly dimmed, green check, delivered chip.
///   • Cancelled → strikethrough text, red X, cancelled chip.
///
/// Interaction: long-press opens a context menu for cancellation.
/// Cancelled and paid items suppress the long-press menu.
class OrderItemTile extends StatelessWidget {
  const OrderItemTile({
    super.key,
    required this.item,
    required this.onCancel,
    required this.onRepeat,
    this.onDelete,
  });

  final OrderItemEntity item;
  final VoidCallback onCancel;

  /// Re-orders this exact line as a new pending item ("repetir ítem").
  final VoidCallback onRepeat;

  /// When non-null and item is cancelled, shows a trash icon for permanent removal.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = switch (item.status) {
      OrderItemStatus.cancelled =>
        isDark ? AppColors.darkDisabled : AppColors.lightDisabled,
      OrderItemStatus.delivered =>
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
      OrderItemStatus.pending =>
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
    };

    return GestureDetector(
      onLongPress:
          item.isCancelled ? null : () => _showActionsMenu(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.space8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: item.isCancelled
                ? AppColors.statusRed.withOpacity(0.3)
                : item.isLiquor
                    ? AppColors.statusPurple.withOpacity(0.35)
                    : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // ── Category icon ────────────────────────────────────────────
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.isCancelled
                    ? AppColors.statusRed.withOpacity(0.1)
                    : item.categoryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(
                item.isCancelled ? Icons.cancel_rounded : item.categoryIcon,
                color: item.isCancelled
                    ? AppColors.statusRed
                    : item.categoryColor,
                size: AppDimensions.iconSm,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),

            // ── Product name + quantity ───────────────────────────────────
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.quantity > 1
                              ? '${item.productName}  ×${item.quantity}'
                              : item.productName,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: textColor,
                            decoration: item.isCancelled
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppColors.statusRed,
                            decorationThickness: 2.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Row(
                    children: [
                      _StatusChip(status: item.status, isPaid: item.isPaid),
                      if (item.isLiquor) ...[
                        const SizedBox(width: AppDimensions.space6),
                        _LiquorBadge(),
                      ],
                    ],
                  ),
                  if (item.note != null && item.note!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.space4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.sticky_note_2_rounded,
                          size: 12,
                          color: AppColors.brand,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.note!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.brand,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppDimensions.space4),
                  _TimestampRow(item: item),
                ],
              ),
            ),

            // ── Line total + optional delete ─────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.lineTotal.toCop,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: item.isCancelled
                        ? AppColors.statusRed.withOpacity(0.6)
                        : item.categoryColor,
                    decoration: item.isCancelled
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (item.isCancelled && onDelete != null)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.statusRed.withOpacity(0.65),
                      onPressed: onDelete,
                    ),
                  )
                else if (item.quantity > 1)
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
          ],
        ),
      ),
    );
  }

  void _showActionsMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.productName,
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.space24),

              // ── Repetir ítem ─────────────────────────────────────────
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRepeat();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: const Color(0xFF1A0A00),
                ),
                icon: const Icon(Icons.replay_rounded),
                label: Text(
                  item.quantity > 1
                      ? 'Repetir (otra vez ×${item.quantity})'
                      : 'Repetir ítem',
                ),
              ),

              // ── Cancelar (solo si no está pagado) ────────────────────
              if (!item.isPaid) ...[
                const SizedBox(height: AppDimensions.space12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusRed,
                    side: BorderSide(
                      color: AppColors.statusRed.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Cancelar ítem'),
                ),
              ],

              const SizedBox(height: AppDimensions.space8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status chip ────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.isPaid});

  final OrderItemStatus status;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      OrderItemStatus.pending => ('PENDIENTE', AppColors.statusOrange, Icons.access_time_rounded),
      OrderItemStatus.delivered => isPaid
          ? ('PAGADO', AppColors.statusGreen, Icons.check_circle_rounded)
          : ('ENTREGADO', AppColors.statusBlue, Icons.check_rounded),
      OrderItemStatus.cancelled => ('CANCELADO', AppColors.statusRed, Icons.cancel_rounded),
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
          Text(label, style: AppTextStyles.statusBadge.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _TimestampRow extends StatelessWidget {
  const _TimestampRow({required this.item});

  final OrderItemEntity item;

  static final _fmt = DateFormat('HH:mm', 'es_CO');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dimColor = isDark ? AppColors.darkDisabled : AppColors.lightDisabled;

    final segments = <String>[];
    segments.add('Pedido ${_fmt.format(item.orderedAt)}');
    if (item.deliveredAt != null) {
      segments.add('Entregado ${_fmt.format(item.deliveredAt!)}');
    }

    return Row(
      children: [
        Icon(Icons.access_time_rounded, size: 10, color: dimColor),
        const SizedBox(width: 3),
        Text(
          segments.join(' · '),
          style: AppTextStyles.labelSmall.copyWith(color: dimColor, fontSize: 10),
        ),
      ],
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
          const Icon(Icons.wine_bar_rounded, size: 11, color: AppColors.statusPurple),
          const SizedBox(width: 4),
          Text(
            'LICOR',
            style: AppTextStyles.statusBadge.copyWith(color: AppColors.statusPurple),
          ),
        ],
      ),
    );
  }
}
