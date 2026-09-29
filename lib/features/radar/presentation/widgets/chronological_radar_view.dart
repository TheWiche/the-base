import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/domain/entities/pending_radar_item.dart';
import '../providers/radar_providers.dart';

/// Vista "Cronológica" del Radar.
///
/// Muestra todos los ítems pendientes ordenados estrictamente por tiempo de
/// llegada (más antiguo primero) para priorizar el despacho según antigüedad.
class ChronologicalRadarView extends ConsumerWidget {
  const ChronologicalRadarView({
    super.key,
    required this.items,
    required this.onDelivered,
  });

  final List<PendingRadarItem> items;
  final void Function(int itemId) onDelivered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(radarClockProvider);

    if (items.isEmpty) return const _EmptyChronologicalRadar();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space8,
        AppDimensions.pagePaddingH,
        AppDimensions.space64,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final radarItem = items[index];
        return _ChronologicalItemCard(
          key: ValueKey('chrono_${radarItem.item.id}'),
          radarItem: radarItem,
          onDelivered: () => onDelivered(radarItem.item.id),
        );
      },
    );
  }
}

class _ChronologicalItemCard extends StatelessWidget {
  const _ChronologicalItemCard({
    super.key,
    required this.radarItem,
    required this.onDelivered,
  });

  final PendingRadarItem radarItem;
  final VoidCallback onDelivered;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = radarItem.item;

    final Color urgencyColor = switch (item.urgency) {
      RadarUrgency.normal => AppColors.secondaryDark,
      RadarUrgency.warning => AppColors.statusOrange,
      RadarUrgency.critical => AppColors.statusRed,
    };

    final cardBg = isDark ? AppColors.darkSurfaceVariant : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space10),
      child: Dismissible(
        key: ValueKey('dismiss_chrono_${item.id}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          HapticFeedback.mediumImpact();
          onDelivered();
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
            color: AppColors.statusGreen.withOpacity(0.25),
            borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          ),
          child: const Row(
            children: [
              Icon(Icons.done_rounded, color: AppColors.statusGreen, size: 28),
              SizedBox(width: 8),
              Text(
                'Entregar',
                style: TextStyle(
                  color: AppColors.statusGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
            border: Border.all(
              color: item.urgency == RadarUrgency.critical
                  ? AppColors.statusRed
                  : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
              width: item.urgency == RadarUrgency.critical ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Badge de tiempo transcurrido ────────────────────────────
                Container(
                  width: 50,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: urgencyColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${item.elapsedMinutes}m',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: urgencyColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),

                // ── Nombre, cantidad, nota y mesa ───────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}× ${item.productName}',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '↳ ${item.note}',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),

                      // Chip interactivo para saltar a la mesa
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push(
                            '/tables/${radarItem.tableSessionId}/orders',
                          );
                        },
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : const Color(0xFFF0F0F5),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkOutline
                                  : AppColors.lightOutline,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.table_restaurant_rounded,
                                size: 13,
                                color: isDark
                                    ? AppColors.darkOnSurfaceVariant
                                    : AppColors.lightOnSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                radarItem.shortTableLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : AppColors.lightOnSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.open_in_new_rounded,
                                size: 11,
                                color: AppColors.paperInkSoft,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppDimensions.space8),

                // ── Botón de entrega rápida ────────────────────────────────
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onDelivered();
                  },
                  tooltip: 'Marcar entregado',
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 28,
                    color: AppColors.statusGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChronologicalRadar extends StatelessWidget {
  const _EmptyChronologicalRadar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.done_all_rounded,
              size: 80,
              color: AppColors.statusGreen.withOpacity(0.4),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              'Todos los pedidos al día',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.statusGreen,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'No hay pedidos pendientes en la cola.',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
