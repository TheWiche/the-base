import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/shift_snapshot.dart';
import '../providers/shift_history_providers.dart';

/// Read-only list of completed shifts, newest first. Tap → detalle completo.
class ShiftHistoryScreen extends ConsumerWidget {
  const ShiftHistoryScreen({super.key});

  static final _dateFormat = DateFormat('dd MMM yyyy · HH:mm', 'es_CO');

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
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: snapshots.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ShiftStub(
                snapshot: snapshots[i],
                dateFormat: _dateFormat,
                index: snapshots.length - i,
                onTap: () =>
                    context.push('/cierre/historial/${snapshots[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Shift stub (talón compacto) ────────────────────────────────────────────────

class _ShiftStub extends StatelessWidget {
  const _ShiftStub({
    required this.snapshot,
    required this.dateFormat,
    required this.index,
    required this.onTap,
  });

  final ShiftSnapshot snapshot;
  final DateFormat dateFormat;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profit = snapshot.netProfit;
    final profitColor =
        profit >= 0 ? AppColors.statusGreen : AppColors.statusRed;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'TURNO #$index',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(snapshot.snapshotAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                    ),
                  ],
                ),
                Divider(
                  height: 18,
                  thickness: 1,
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MiniStat(
                      label: 'DEUDA',
                      value: snapshot.totalDebt.toCop,
                      isDark: isDark,
                    ),
                    _MiniStat(
                      label: 'EFECTIVO',
                      value: snapshot.cashInHand.toCop,
                      isDark: isDark,
                    ),
                    _MiniStat(
                      label: 'UTILIDAD',
                      value: profit.toSignedCop,
                      color: profitColor,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color? color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.lightOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color ??
                (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
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
