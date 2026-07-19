import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/domain/entities/pending_radar_item.dart';
import '../providers/radar_providers.dart';

/// El Radar "Por Mesa" — cada mesa es una COMANDA de papel (tiquete de cocina):
/// encabezado con la mesa y el pedido más viejo, líneas de tiquete con su
/// badge de minutos y nota, y un botón-sello "Entregar todo" al pie.
class GroupedTableView extends ConsumerWidget {
  const GroupedTableView({
    super.key,
    required this.groups,
    required this.onDelivered,
    required this.onDeliverAll,
  });

  final List<RadarTableGroup> groups;
  final void Function(int itemId) onDelivered;
  final void Function(int sessionId) onDeliverAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tick de 30s para mantener frescos los minutos transcurridos.
    ref.watch(radarClockProvider);

    if (groups.isEmpty) return const _EmptyRadar();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space8,
        AppDimensions.pagePaddingH,
        AppDimensions.space64,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) => _ComandaCard(
        group: groups[index],
        onDelivered: onDelivered,
        onDeliverAll: onDeliverAll,
      ),
    );
  }
}

// ── Comanda (una mesa) ─────────────────────────────────────────────────────────

class _ComandaCard extends StatelessWidget {
  const _ComandaCard({
    required this.group,
    required this.onDelivered,
    required this.onDeliverAll,
  });

  final RadarTableGroup group;
  final void Function(int itemId) onDelivered;
  final void Function(int sessionId) onDeliverAll;

  @override
  Widget build(BuildContext context) {
    final sessionId = group.items.first.item.tableSessionId;
    final oldest = group.items
        .map((i) => i.item.elapsedMinutes)
        .fold(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space16),
      child: ReceiptPaper(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Encabezado ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MESA ${group.tableNumber}',
                        style: AppTextStyles.receiptTitle.copyWith(
                          fontSize: 16,
                          color: AppColors.paperInk,
                        ),
                      ),
                      if (group.tableApodo != null)
                        Text(
                          '"${group.tableApodo}"',
                          style: AppTextStyles.receiptSmall.copyWith(
                            color: AppColors.paperInkSoft,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                _ElapsedBadge(minutes: oldest),
              ],
            ),
            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 8)),

            // ── Líneas de la comanda ───────────────────────────────
            for (final radarItem in group.items)
              _ComandaLine(
                key: ValueKey(radarItem.item.id),
                item: radarItem.item,
                onDelivered: () => onDelivered(radarItem.item.id),
              ),

            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 8)),

            // ── Entregar todo (sello) ──────────────────────────────
            FilledButton.icon(
              onPressed: () => onDeliverAll(sessionId),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(42),
              ),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Entregar todo'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Línea de comanda (swipe → entregar) ───────────────────────────────────────

class _ComandaLine extends StatelessWidget {
  const _ComandaLine({
    super.key,
    required this.item,
    required this.onDelivered,
  });

  final OrderItemEntity item;
  final VoidCallback onDelivered;

  Color get _urgencyColor => switch (item.urgency) {
        RadarUrgency.normal => AppColors.secondaryDark,
        RadarUrgency.warning => AppColors.statusOrange,
        RadarUrgency.critical => AppColors.statusRed,
      };

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${item.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onDelivered();
        return false; // el stream refresca la lista; no removemos localmente
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 12),
        color: AppColors.statusGreen.withOpacity(0.25),
        child: const Icon(Icons.done_rounded, color: AppColors.statusGreen),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minutos
            SizedBox(
              width: 44,
              child: Text(
                '${item.elapsedMinutes}m',
                style: AppTextStyles.receiptBodyBold
                    .copyWith(color: _urgencyColor),
              ),
            ),
            // Producto + nota
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}× ${item.productName}',
                    style: AppTextStyles.receiptBody
                        .copyWith(color: AppColors.paperInk),
                  ),
                  if (item.note != null && item.note!.isNotEmpty)
                    Text(
                      '↳ ${item.note}',
                      style: AppTextStyles.receiptSmall.copyWith(
                        color: AppColors.paperInkSoft,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            // Entregar esta línea
            IconButton(
              onPressed: onDelivered,
              visualDensity: VisualDensity.compact,
              tooltip: 'Entregado',
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.secondaryDark,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Elapsed badge del encabezado ──────────────────────────────────────────────

class _ElapsedBadge extends StatelessWidget {
  const _ElapsedBadge({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final color = minutes >= 10
        ? AppColors.statusRed
        : (minutes >= 5 ? AppColors.statusOrange : AppColors.secondaryDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyRadar extends StatelessWidget {
  const _EmptyRadar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.radar_rounded,
            size: 80,
            color: AppColors.statusGreen.withOpacity(0.4),
          ),
          const SizedBox(height: AppDimensions.space16),
          Text(
            'Comanda limpia',
            style: AppTextStyles.headlineMedium
                .copyWith(color: AppColors.statusGreen),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text('Todo entregado. Estás al día.', style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}
