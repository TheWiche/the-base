import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/shift_snapshot.dart';
import '../providers/shift_history_providers.dart';

/// Read-only list of completed shifts, newest first.
class ShiftHistoryScreen extends ConsumerWidget {
  const ShiftHistoryScreen({super.key});

  static final _dateFormat = DateFormat('EEEE dd MMM yyyy · HH:mm', 'es_CO');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(shiftHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Turnos', style: AppTextStyles.headlineSmall),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error al cargar el historial.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.statusRed),
          ),
        ),
        data: (snapshots) {
          if (snapshots.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.space12,
              horizontal: AppDimensions.pagePaddingH,
            ),
            itemCount: snapshots.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.space8),
            itemBuilder: (_, i) => _ShiftCard(
              snapshot: snapshots[i],
              dateFormat: _dateFormat,
              index: snapshots.length - i,
            ),
          );
        },
      ),
    );
  }
}

// ── Shift card ─────────────────────────────────────────────────────────────────

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.snapshot,
    required this.dateFormat,
    required this.index,
  });

  final ShiftSnapshot snapshot;
  final DateFormat dateFormat;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profit = snapshot.netProfit;
    final profitColor =
        profit >= 0 ? AppColors.statusGreen : AppColors.statusRed;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space8,
                  vertical: AppDimensions.space2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  'Turno #$index',
                  style: AppTextStyles.statusBadge
                      .copyWith(color: AppColors.brand),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.schedule_rounded,
                size: 12,
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(snapshot.snapshotAt),
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.space16),

          // ── Key metrics row ───────────────────────────────────────────
          Row(
            children: [
              _Metric(
                label: 'DEUDA TOTAL',
                value: snapshot.totalDebt.toCop,
                color: isDark
                    ? AppColors.darkOnSurface
                    : AppColors.lightOnSurface,
              ),
              const SizedBox(width: AppDimensions.space16),
              _Metric(
                label: 'EFECTIVO',
                value: snapshot.cashInHand.toCop,
                color: AppColors.statusBlue,
              ),
              const SizedBox(width: AppDimensions.space16),
              _Metric(
                label: 'UTILIDAD',
                value: profit.toSignedCop,
                color: profitColor,
                highlight: true,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.space12),
          Divider(
            height: 1,
            color: isDark
                ? AppColors.darkOutlineVariant
                : AppColors.lightOutlineVariant,
          ),
          const SizedBox(height: AppDimensions.space12),

          // ── Secondary metrics ─────────────────────────────────────────
          Wrap(
            spacing: AppDimensions.space16,
            runSpacing: AppDimensions.space6,
            children: [
              _SecondaryMetric(
                label: 'Base capital',
                value: (snapshot.initialBase +
                        snapshot.totalIncreases -
                        snapshot.totalDecreases)
                    .toCop,
              ),
              _SecondaryMetric(
                label: 'Licor',
                value: snapshot.totalLiquorDebt.toCop,
              ),
              if (snapshot.verifiedTransfersTotal > 0)
                _SecondaryMetric(
                  label: 'Transferencias',
                  value: snapshot.verifiedTransfersTotal.toCop,
                ),
              if (snapshot.transferTipsTotal > 0)
                _SecondaryMetric(
                  label: 'Propinas',
                  value: snapshot.transferTipsTotal.toCop,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Metric widgets ─────────────────────────────────────────────────────────────

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.statusBadge.copyWith(
              color: color.withValues(alpha: highlight ? 1.0 : 0.7),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SecondaryMetric extends StatelessWidget {
  const _SecondaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: AppTextStyles.labelSmall.copyWith(
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.lightOnSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelSmall.copyWith(
            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.work_history_rounded,
              size: 72,
              color: AppColors.brand.withValues(alpha: 0.25),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              'Sin turnos anteriores',
              style: AppTextStyles.headlineMedium
                  .copyWith(color: AppColors.brand),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Los turnos finalizados aparecerán aquí.',
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
