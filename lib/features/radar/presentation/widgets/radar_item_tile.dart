import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/domain/entities/pending_radar_item.dart';
import '../providers/radar_providers.dart';

/// A single item row in El Radar (KDS), with:
///   • Live elapsed-time ticker (updates every 30 s via [radarClockProvider]).
///   • Urgency color-coding: normal → warning → critical.
///   • Swipe-right gesture to mark delivered instantly.
///   • "ENTREGADO" button as an alternative tap target.
///
/// The [radarClockProvider] watch causes ALL visible radar tiles to rebuild
/// synchronously when the tick fires — keeping all elapsed labels in sync.
class RadarItemTile extends ConsumerWidget {
  const RadarItemTile({
    super.key,
    required this.radarItem,
    required this.onDelivered,
    this.showTableLabel = true,
  });

  final PendingRadarItem radarItem;
  final VoidCallback onDelivered;

  /// False in the grouped view where the table header already identifies the group.
  final bool showTableLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribing to the clock ticker forces a rebuild every 30 seconds.
    // The tile recomputes elapsed time directly from DateTime.now().
    ref.watch(radarClockProvider);

    final item = radarItem.item;
    final elapsed = item.elapsed;
    final urgency = item.urgency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final urgencyColor = switch (urgency) {
      RadarUrgency.normal => AppColors.statusGreen,
      RadarUrgency.warning => AppColors.statusOrange,
      RadarUrgency.critical => AppColors.statusRed,
    };

    final elapsedLabel = RadarUrgencyUI.formatElapsed(elapsed);

    return Dismissible(
      key: ValueKey('radar_${item.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppDimensions.space24),
        decoration: BoxDecoration(
          color: AppColors.statusGreen,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
            const SizedBox(width: AppDimensions.space8),
            Text(
              'ENTREGADO',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return true;
      },
      onDismissed: (_) => onDelivered(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.space8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: urgencyColor.withOpacity(urgency == RadarUrgency.normal ? 0.25 : 0.55),
            width: urgency == RadarUrgency.critical ? 2.0 : 1.5,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ── Urgency stripe ────────────────────────────────────────
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusMd),
                    bottomLeft: Radius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),

              // ── Content (tap → navigate to table orders) ──────────────
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push(
                    '/tables/${radarItem.tableSessionId}/orders',
                  ),
                  child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space12,
                    vertical: AppDimensions.space10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top row: table label + elapsed ─────────────────
                      Row(
                        children: [
                          if (showTableLabel) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.brand.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusFull),
                              ),
                              child: Text(
                                radarItem.shortTableLabel,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.brand,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space8),
                          ],
                          const Spacer(),
                          // Elapsed ticker
                          _ElapsedBadge(
                            label: elapsedLabel,
                            color: urgencyColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.space6),

                      // ── Product name + quantity ─────────────────────────
                      Row(
                        children: [
                          Icon(
                            item.categoryIcon,
                            color: item.categoryColor,
                            size: AppDimensions.iconSm,
                          ),
                          const SizedBox(width: AppDimensions.space6),
                          Expanded(
                            child: Text(
                              item.quantity > 1
                                  ? '${item.productName}  ×${item.quantity}'
                                  : item.productName,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: isDark
                                    ? AppColors.darkOnSurface
                                    : AppColors.lightOnSurface,
                              ),
                            ),
                          ),
                          Text(
                            item.lineTotal.toCop,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: item.categoryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      // ── Nota del ítem (si tiene) ───────────────────────
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.space6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.sticky_note_2_rounded,
                                size: 14, color: AppColors.statusOrange),
                            const SizedBox(width: AppDimensions.space6),
                            Expanded(
                              child: Text(
                                item.note!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.statusOrange,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                ),
              ),

              // ── Deliver button ────────────────────────────────────────
              _DeliverButton(onPressed: onDelivered),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Elapsed badge ─────────────────────────────────────────────────────────────

class _ElapsedBadge extends StatelessWidget {
  const _ElapsedBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.statusBadge.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ── Deliver button ─────────────────────────────────────────────────────────────

class _DeliverButton extends StatelessWidget {
  const _DeliverButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: 56,
        decoration: BoxDecoration(
          color: AppColors.statusGreen.withOpacity(0.12),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(AppDimensions.radiusMd),
            bottomRight: Radius.circular(AppDimensions.radiusMd),
          ),
          border: Border(
            left: BorderSide(
              color: AppColors.statusGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded,
                color: AppColors.statusGreen, size: AppDimensions.iconMd),
            const SizedBox(height: 2),
            Text(
              'Listo',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.statusGreen),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
