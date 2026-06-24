import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/stagger_entrance.dart';
import '../../../orders/domain/entities/pending_radar_item.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../providers/radar_providers.dart';
import '../widgets/grouped_table_view.dart';
import '../widgets/radar_item_tile.dart';

/// El Radar — the KDS (Kitchen Display System) screen.
///
/// Displays all pending order items across every active table, with two
/// switchable views:
///   • Chronological — flat list ordered oldest-first (global urgency ranking).
///   • Por Mesa       — items grouped by table, groups ordered by oldest item.
///
/// Each tile has a swipe-right gesture and a tap button to mark delivery.
/// The live elapsed-time ticker is driven by [radarClockProvider].
class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(radarViewModeProvider);
    final radarAsync = ref.watch(pendingRadarItemsProvider);
    final pendingCount = ref.watch(pendingRadarCountProvider);
    final deliver = ref.read(deliverItemProvider);

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
            Text('Pedidos', style: AppTextStyles.headlineMedium),
            const Spacer(),
            if (pendingCount > 0) _PendingCountBadge(count: pendingCount),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePaddingH,
              0,
              AppDimensions.pagePaddingH,
              AppDimensions.space8,
            ),
            child: SegmentedButton<RadarViewMode>(
              segments: const [
                ButtonSegment<RadarViewMode>(
                  value: RadarViewMode.grouped,
                  icon: Icon(Icons.table_restaurant_rounded),
                  label: Text('Por Mesa'),
                ),
                ButtonSegment<RadarViewMode>(
                  value: RadarViewMode.chronological,
                  icon: Icon(Icons.view_list_rounded),
                  label: Text('Cronológico'),
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (selection) {
                ref.read(radarViewModeProvider.notifier).state = selection.first;
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.brand.withOpacity(0.15),
                selectedForegroundColor: AppColors.brand,
                minimumSize: const Size(0, AppDimensions.tapTargetStd),
              ),
            ),
          ),
        ),
      ),
      body: radarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RadarErrorBody(error: error),
        data: (items) {
          if (items.isEmpty) return const _EmptyRadarBody();
          return switch (viewMode) {
            RadarViewMode.chronological => _ChronologicalView(
                items: items,
                onDelivered: (id) => _onDeliver(id, deliver),
              ),
            RadarViewMode.grouped => GroupedTableView(
                groups: ref.watch(radarGroupedProvider),
                onDelivered: (id) => _onDeliver(id, deliver),
              ),
          };
        },
      ),
    );
  }

  Future<void> _onDeliver(
    int itemId,
    Future<Failure?> Function(int) deliver,
  ) async {
    final failure = await deliver(itemId);
    if (failure != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.statusRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Chronological flat view (staggered entrance on mount) ─────────────────────

class _ChronologicalView extends StatefulWidget {
  const _ChronologicalView({
    required this.items,
    required this.onDelivered,
  });

  final List<PendingRadarItem> items;
  final void Function(int itemId) onDelivered;

  @override
  State<_ChronologicalView> createState() => _ChronologicalViewState();
}

class _ChronologicalViewState extends State<_ChronologicalView>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerCtrl;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _rebuild(widget.items.length);
    _staggerCtrl.forward();
  }

  void _rebuild(int n) {
    final count = n.clamp(1, 25);
    _staggerCtrl = createStaggerController(vsync: this, itemCount: count);
    _anims = buildStaggerAnimations(
      controller: _staggerCtrl,
      itemCount: count,
    );
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.items]
      ..sort((a, b) => a.item.orderedAt.compareTo(b.item.orderedAt));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space8,
        AppDimensions.pagePaddingH,
        AppDimensions.space64,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final radarItem = sorted[index];
        final anim = index < _anims.length ? _anims[index] : _anims.last;
        return StaggerItem(
          animation: anim,
          child: RadarItemTile(
            key: ValueKey(radarItem.item.id),
            radarItem: radarItem,
            showTableLabel: true,
            onDelivered: () => widget.onDelivered(radarItem.item.id),
          ),
        );
      },
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
