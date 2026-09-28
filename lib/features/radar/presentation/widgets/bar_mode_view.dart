import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../domain/entities/radar_bar_batch.dart';
import '../providers/radar_providers.dart';

/// Vista consolidada "Modo Barra" (Bulk Batching).
///
/// Agrupa todos los ítems pendientes por entregar de todas las mesas activas
/// en lotes por producto idéntico y notas.
///
/// Permite:
/// 1. Ver a gran distancia el total consolidado (ej. `[4x] Michelada Póker`).
/// 2. Ver desglose claro por mesas (ej. `Mesa 1: 1 | Mesa 3: 2`).
/// 3. Despachar mesa por mesa o el lote completo ("Completar Todo").
class BarModeView extends ConsumerWidget {
  const BarModeView({
    super.key,
    required this.batches,
    required this.onDeliverBatch,
    required this.onDeliverSubBatch,
  });

  final List<RadarBarBatch> batches;
  final void Function(List<int> itemIds) onDeliverBatch;
  final void Function(List<int> itemIds) onDeliverSubBatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reconstrucción reactiva periódica con el reloj
    ref.watch(radarClockProvider);

    if (batches.isEmpty) return const _EmptyBarMode();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space8,
        AppDimensions.pagePaddingH,
        AppDimensions.space64,
      ),
      itemCount: batches.length,
      itemBuilder: (context, index) => _BarBatchCard(
        key: ValueKey(
          'batch_${batches[index].productName}_${batches[index].note}_${batches[index].totalQuantity}',
        ),
        batch: batches[index],
        onDeliverAll: () => onDeliverBatch(batches[index].allItemIds),
        onDeliverSubBatch: onDeliverSubBatch,
      ),
    );
  }
}

// ── Tarjeta de lote consolidado en barra ──────────────────────────────────────

class _BarBatchCard extends StatelessWidget {
  const _BarBatchCard({
    super.key,
    required this.batch,
    required this.onDeliverAll,
    required this.onDeliverSubBatch,
  });

  final RadarBarBatch batch;
  final VoidCallback onDeliverAll;
  final void Function(List<int> itemIds) onDeliverSubBatch;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color urgencyBorderColor = switch (batch.urgency) {
      RadarUrgency.critical => AppColors.statusRed,
      RadarUrgency.warning => AppColors.statusOrange,
      RadarUrgency.normal => isDark
          ? AppColors.darkOutline.withOpacity(0.5)
          : AppColors.lightOutline.withOpacity(0.5),
    };

    final Color urgencyBgTint = switch (batch.urgency) {
      RadarUrgency.critical => AppColors.statusRed.withOpacity(0.08),
      RadarUrgency.warning => AppColors.statusOrange.withOpacity(0.05),
      RadarUrgency.normal => Colors.transparent,
    };

    final cardBg = isDark ? const Color(0xFF1E1E28) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: batch.urgency != RadarUrgency.normal
                ? urgencyBorderColor
                : (isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E2EA)),
            width: batch.urgency == RadarUrgency.critical ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            color: urgencyBgTint,
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Cabecera: Badge grande + Nombre del producto + Tiempo ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge numérico grande y destacado para lectura a distancia
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space12,
                        vertical: AppDimensions.space6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '[${batch.totalQuantity}x]',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),

                    // Nombre del producto y notas
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            batch.productName,
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              height: 1.2,
                            ),
                          ),
                          if (batch.note != null && batch.note!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primaryDark)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '↳ ${batch.note}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: AppDimensions.space8),

                    // Badge de tiempo transcurrido
                    _BarElapsedBadge(minutes: batch.elapsedMinutes),
                  ],
                ),

                const SizedBox(height: AppDimensions.space12),
                const Divider(height: 1, thickness: 0.8),
                const SizedBox(height: AppDimensions.space12),

                // ── Sub-desglose por mesas (chips legibles) ─────────────────
                Row(
                  children: [
                    Icon(
                      Icons.table_restaurant_outlined,
                      size: 15,
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Destinos por mesa (toca para despachar mesa):',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space8),

                Wrap(
                  spacing: AppDimensions.space8,
                  runSpacing: AppDimensions.space8,
                  children: [
                    for (final subBatch in batch.tableDestinations)
                      _TableDestinationChip(
                        subBatch: subBatch,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onDeliverSubBatch(subBatch.itemIds);
                        },
                      ),
                  ],
                ),

                const SizedBox(height: AppDimensions.space16),

                // ── Botón: Completar Lote Completo ─────────────────────────
                FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    onDeliverAll();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.statusGreen,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                  ),
                  icon: const Icon(Icons.done_all_rounded, size: 20),
                  label: Text(
                    'Completar Todo (${batch.totalQuantity})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
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

// ── Chip para entrega individual por mesa ─────────────────────────────────────

class _TableDestinationChip extends StatelessWidget {
  const _TableDestinationChip({
    required this.subBatch,
    required this.onTap,
  });

  final RadarBarSubBatch subBatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final apodoText = (subBatch.tableApodo != null &&
            subBatch.tableApodo!.isNotEmpty)
        ? ' · "${subBatch.tableApodo}"'
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF282838)
                : const Color(0xFFF1F1F6),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3F3F56)
                  : const Color(0xFFD4D4E0),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mesa ${subBatch.tableNumber}$apodoText:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF333340),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${subBatch.quantity}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: AppColors.statusGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Elapsed Badge para tarjeta de barra ───────────────────────────────────────

class _BarElapsedBadge extends StatelessWidget {
  const _BarElapsedBadge({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final Color color = minutes >= 10
        ? AppColors.statusRed
        : (minutes >= 5 ? AppColors.statusOrange : AppColors.secondaryDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        minutes < 1 ? 'ahora' : 'hace ${minutes}m',
        style: AppTextStyles.receiptSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Estado vacío para Modo Barra ──────────────────────────────────────────────

class _EmptyBarMode extends StatelessWidget {
  const _EmptyBarMode();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wine_bar_rounded,
              size: 80,
              color: AppColors.statusGreen.withOpacity(0.4),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              'Barra al día',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.statusGreen,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'No hay bebidas ni licores pendientes por preparar.',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
