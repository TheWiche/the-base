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

/// El Radar "Por Mesa" — cada mesa es una COMANDA de papel (tiquete de cocina):
/// encabezado con la mesa y el pedido más viejo, líneas de tiquete con su
/// badge de minutos y nota, y un botón-sello "Entregar todo" al pie.
///
/// También dispara una vibración fuerte, UNA sola vez por ítem, cuando este
/// cruza a urgencia crítica (10+ min) — para que no se pase por alto en un
/// ambiente ruidoso. Se trackean los ids ya alertados para no repetir en
/// cada tick del reloj de 30s.
class GroupedTableView extends ConsumerStatefulWidget {
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
  ConsumerState<GroupedTableView> createState() => _GroupedTableViewState();
}

class _GroupedTableViewState extends ConsumerState<GroupedTableView> {
  final _alertedIds = <int>{};

  void _checkCriticalAlerts() {
    final presentIds = <int>{};
    var hasNewCritical = false;
    for (final group in widget.groups) {
      for (final radarItem in group.items) {
        final id = radarItem.item.id;
        presentIds.add(id);
        if (radarItem.item.urgency == RadarUrgency.critical &&
            _alertedIds.add(id)) {
          hasNewCritical = true;
        }
      }
    }
    // Olvida ids que ya no están pendientes (entregados/cancelados).
    _alertedIds.retainWhere(presentIds.contains);
    if (hasNewCritical) HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    // Tick de 30s para mantener frescos los minutos transcurridos.
    ref.watch(radarClockProvider);

    // Se evalúa después del frame — build() debe permanecer libre de efectos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkCriticalAlerts();
    });

    if (widget.groups.isEmpty) return const _EmptyRadar();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space8,
        AppDimensions.pagePaddingH,
        AppDimensions.space64,
      ),
      itemCount: widget.groups.length,
      itemBuilder: (context, index) => _ComandaCard(
        group: widget.groups[index],
        onDelivered: widget.onDelivered,
        onDeliverAll: widget.onDeliverAll,
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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paperSurface,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          border: Border.all(
            color: AppColors.paperBorder,
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.paperShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Encabezado (tocar para ir a la cuenta de la mesa) ────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/tables/$sessionId/orders');
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'MESA ${group.tableNumber}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (group.tableApodo != null)
                        Expanded(
                          child: Text(
                            '"${group.tableApodo}"',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const Spacer(),
                      _ElapsedBadge(minutes: oldest),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(
              color: AppColors.paperBorder,
              height: 20,
            ),

            // ── Líneas de la comanda ───────────────────────────────
            for (final radarItem in group.items)
              _ComandaLine(
                key: ValueKey(radarItem.item.id),
                item: radarItem.item,
                onDelivered: () => onDelivered(radarItem.item.id),
              ),

            const Divider(
              color: AppColors.paperBorder,
              height: 20,
            ),

            // ── Entregar todo (botón estándar 52px, 14px radius) ───
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.heavyImpact();
                onDeliverAll(sessionId);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: const Text(
                'Entregar todo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
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
        HapticFeedback.mediumImpact();
        onDelivered();
        return false; // el stream refresca la lista; no removemos localmente
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 12),
        color: AppColors.statusGreen.withValues(alpha: 0.2),
        child: const Icon(Icons.done_rounded, color: AppColors.statusGreen),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minutos
            SizedBox(
              width: 44,
              child: Text(
                '${item.elapsedMinutes}m',
                style: AppTextStyles.receiptBodyBold.copyWith(
                  color: _urgencyColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Producto + nota
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: '${item.quantity}× ',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (item.note != null && item.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '↳ ${item.note}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Entregar esta línea
            IconButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onDelivered();
              },
              visualDensity: VisualDensity.compact,
              tooltip: 'Entregado',
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.statusGreen,
                size: 24,
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.45)),
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
