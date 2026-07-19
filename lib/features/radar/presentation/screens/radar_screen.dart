import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../providers/radar_providers.dart';
import '../widgets/grouped_table_view.dart';

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
    final radarAsync = ref.watch(pendingRadarItemsProvider);
    final pendingCount = ref.watch(pendingRadarCountProvider);
    final deliver = ref.read(deliverItemProvider);
    final deliverAll = ref.read(deliverTableProvider);

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
      ),
      body: radarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RadarErrorBody(error: error),
        data: (items) {
          if (items.isEmpty) return const _EmptyRadarBody();
          return GroupedTableView(
            groups: ref.watch(radarGroupedProvider),
            onDelivered: (id) => _onDeliver(id, deliver),
            onDeliverAll: (sessionId) => _onDeliver(sessionId, deliverAll),
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
