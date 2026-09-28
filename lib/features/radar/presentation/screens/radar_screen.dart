import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../providers/radar_providers.dart';
import '../widgets/bar_mode_view.dart';
import '../widgets/chronological_radar_view.dart';
import '../widgets/grouped_table_view.dart';

/// El Radar — KDS (Kitchen Display System) y Despacho de Pedidos.
///
/// Dispone de 3 modos seleccionables:
///   1. Cronológico: por orden de llegada con tiempo transcurrido individual.
///   2. Por Mesas: agrupado por apodo/número de mesa (formato comanda de papel).
///   3. Modo Barra: consolidado por productos idénticos para lectura a distancia
///      y preparación en masa (bulk batching).
class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  @override
  Widget build(BuildContext context) {
    final radarAsync = ref.watch(pendingRadarItemsProvider);
    final pendingCount = ref.watch(pendingRadarCountProvider);
    final viewMode = ref.watch(radarViewModeProvider);

    final deliver = ref.read(deliverItemProvider);
    final deliverAll = ref.read(deliverTableProvider);
    final deliverBatch = ref.read(deliverItemsBatchProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(
              Icons.pending_actions_rounded,
              color: AppColors.brand,
              size: 28,
            ),
            const SizedBox(width: AppDimensions.space8),
            Text('El Radar', style: AppTextStyles.headlineMedium),
            const Spacer(),
            if (pendingCount > 0) _PendingCountBadge(count: pendingCount),
          ],
        ),
      ),
      body: radarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RadarErrorBody(error: error),
        data: (items) {
          return Column(
            children: [
              // ── Selector tripartito superior ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePaddingH,
                  AppDimensions.space8,
                  AppDimensions.pagePaddingH,
                  AppDimensions.space8,
                ),
                child: _RadarViewSelector(
                  currentMode: viewMode,
                  onModeChanged: (mode) {
                    HapticFeedback.selectionClick();
                    ref.read(radarViewModeProvider.notifier).state = mode;
                  },
                ),
              ),

              // ── Contenido según el modo activo ───────────────────────────
              Expanded(
                child: items.isEmpty
                    ? const _EmptyRadarBody()
                    : switch (viewMode) {
                        RadarViewMode.barra => BarModeView(
                            batches: ref.watch(radarBarBatchesProvider),
                            onDeliverBatch: (ids) =>
                                _onDeliverBatch(ids, deliverBatch),
                            onDeliverSubBatch: (ids) =>
                                _onDeliverBatch(ids, deliverBatch),
                          ),
                        RadarViewMode.mesas => GroupedTableView(
                            groups: ref.watch(radarGroupedProvider),
                            onDelivered: (id) => _onDeliver(id, deliver),
                            onDeliverAll: (sessionId) =>
                                _onDeliver(sessionId, deliverAll),
                          ),
                        RadarViewMode.cronologico => ChronologicalRadarView(
                            items: items,
                            onDelivered: (id) => _onDeliver(id, deliver),
                          ),
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onDeliver(
    int id,
    Future<Failure?> Function(int) action,
  ) async {
    final failure = await action(id);
    if (failure != null && mounted) {
      AppToast.error(context, failure.message);
    }
  }

  Future<void> _onDeliverBatch(
    List<int> ids,
    Future<Failure?> Function(List<int>) action,
  ) async {
    final failure = await action(ids);
    if (failure != null && mounted) {
      AppToast.error(context, failure.message);
    }
  }
}

// ── Selector de Modo de Radar ────────────────────────────────────────────────

class _RadarViewSelector extends StatelessWidget {
  const _RadarViewSelector({
    required this.currentMode,
    required this.onModeChanged,
  });

  final RadarViewMode currentMode;
  final ValueChanged<RadarViewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E28) : const Color(0xFFE8E8EE),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildSegment(
            context,
            mode: RadarViewMode.cronologico,
            title: 'Cronológico',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(width: 4),
          _buildSegment(
            context,
            mode: RadarViewMode.mesas,
            title: 'Por Mesas',
            icon: Icons.receipt_long_rounded,
          ),
          const SizedBox(width: 4),
          _buildSegment(
            context,
            mode: RadarViewMode.barra,
            title: 'Modo Barra',
            icon: Icons.wine_bar_rounded,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required RadarViewMode mode,
    required String title,
    required IconData icon,
    bool highlight = false,
  }) {
    final isSelected = currentMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = highlight
        ? AppColors.primary
        : (isDark ? const Color(0xFF2E2E3E) : Colors.white);
    final selectedFg = highlight
        ? Colors.black
        : (isDark ? Colors.white : Colors.black);
    final unselectedFg = isDark ? Colors.white60 : Colors.black54;

    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? selectedFg : unselectedFg,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? selectedFg : unselectedFg,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyRadarBody extends StatelessWidget {
  const _EmptyRadarBody();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pending_actions_rounded,
              size: 80,
              color: AppColors.statusGreen.withOpacity(0.4),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              'Sin pedidos pendientes',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.statusGreen,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Todo entregado. Estás al día.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────

class _RadarErrorBody extends StatelessWidget {
  const _RadarErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.statusRed,
              size: 48,
            ),
            const SizedBox(height: AppDimensions.space12),
            Text(
              'Error al cargar el radar',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.statusRed,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              error.toString(),
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending count badge ────────────────────────────────────────────────────────

class _PendingCountBadge extends StatelessWidget {
  const _PendingCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.statusRed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.statusBadge.copyWith(color: Colors.white),
      ),
    );
  }
}
