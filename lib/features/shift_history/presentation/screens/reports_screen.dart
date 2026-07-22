import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../data/models/shift_snapshot.dart';
import '../providers/shift_history_providers.dart';

/// Reportes — agrega el historial de turnos ya guardado (ShiftSnapshot).
///
/// Nota honesta: solo hay totales financieros por turno (base, deuda,
/// efectivo, ganancia). No hay desglose por producto — esos datos se
/// borran en el Cierre de cada turno y nunca se agregan aparte.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(shiftHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Reportes', style: AppTextStyles.headlineSmall)),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error al cargar el historial.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.statusRed)),
        ),
        data: (snapshots) {
          if (snapshots.isEmpty) return const _EmptyState();
          // El historial viene newest-first; para el gráfico se quiere
          // cronológico (oldest→newest) de los últimos 14 turnos.
          final chronological = snapshots.reversed.toList();
          final recent = chronological.length > 14
              ? chronological.sublist(chronological.length - 14)
              : chronological;

          final totalProfit = snapshots.fold(0, (s, x) => s + x.netProfit);
          final totalRevenue = snapshots.fold(
              0, (s, x) => s + x.cashPaymentsTotal + x.verifiedTransfersTotal);
          final avgProfit = totalProfit ~/ snapshots.length;
          final best = snapshots.reduce((a, b) => a.netProfit >= b.netProfit ? a : b);
          final worst = snapshots.reduce((a, b) => a.netProfit <= b.netProfit ? a : b);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: ReceiptPaper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'RESUMEN GENERAL',
                    style: AppTextStyles.receiptTitle
                        .copyWith(fontSize: 16, color: AppColors.paperInk),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${snapshots.length} turno${snapshots.length == 1 ? '' : 's'} registrado${snapshots.length == 1 ? '' : 's'}',
                    style: AppTextStyles.receiptSmall
                        .copyWith(color: AppColors.paperInkSoft),
                    textAlign: TextAlign.center,
                  ),
                  const DashedDivider(padding: EdgeInsets.symmetric(vertical: 12)),

                  ReceiptRow(label: 'Ingresos totales', value: totalRevenue.toCop),
                  ReceiptRow(
                    label: 'Ganancia total',
                    value: totalProfit.toSignedCop,
                    bold: true,
                    color: totalProfit >= 0 ? AppColors.secondaryDark : AppColors.statusRed,
                  ),
                  ReceiptRow(label: 'Promedio por turno', value: avgProfit.toSignedCop),

                  const DashedDivider(padding: EdgeInsets.symmetric(vertical: 12)),

                  Row(
                    children: [
                      Expanded(
                        child: _BestWorstCard(
                          label: 'MEJOR TURNO',
                          snapshot: best,
                          color: AppColors.secondaryDark,
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BestWorstCard(
                          label: 'PEOR TURNO',
                          snapshot: worst,
                          color: AppColors.statusRed,
                          icon: Icons.trending_down_rounded,
                        ),
                      ),
                    ],
                  ),

                  const DashedDivider(padding: EdgeInsets.symmetric(vertical: 12)),

                  Text(
                    'ÚLTIMOS ${recent.length} TURNOS · GANANCIA',
                    style: AppTextStyles.receiptBodyBold
                        .copyWith(color: AppColors.paperInk),
                  ),
                  const SizedBox(height: 10),
                  _ProfitBarChart(snapshots: recent),

                  const SizedBox(height: 10),
                  Text(
                    'Solo se agregan los totales de dinero de cada turno — sin\n'
                    'desglose por producto (esos datos no sobreviven al Cierre).',
                    style: AppTextStyles.receiptSmall.copyWith(
                      color: AppColors.paperInkSoft,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Mejor / peor turno ─────────────────────────────────────────────────────────

class _BestWorstCard extends StatelessWidget {
  const _BestWorstCard({
    required this.label,
    required this.snapshot,
    required this.color,
    required this.icon,
  });

  final String label;
  final ShiftSnapshot snapshot;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTextStyles.receiptSmall
                      .copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            snapshot.netProfit.toSignedCop,
            style: AppTextStyles.receiptBodyBold.copyWith(color: color, fontSize: 15),
          ),
          Text(
            DateFormat('d MMM yyyy', 'es_CO').format(snapshot.snapshotAt),
            style: AppTextStyles.receiptSmall.copyWith(color: AppColors.paperInkSoft),
          ),
        ],
      ),
    );
  }
}

// ── Mini gráfico de barras (sin dependencias externas) ────────────────────────

class _ProfitBarChart extends StatelessWidget {
  const _ProfitBarChart({required this.snapshots});

  final List<ShiftSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final maxAbs = snapshots
        .map((s) => s.netProfit.abs())
        .fold(1, (a, b) => a > b ? a : b);
    const chartHeight = 90.0;

    return SizedBox(
      height: chartHeight + 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final s in snapshots)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Tooltip(
                  message: s.netProfit.toSignedCop,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: chartHeight *
                            (s.netProfit.abs() / maxAbs).clamp(0.03, 1.0),
                        decoration: BoxDecoration(
                          color: s.netProfit >= 0
                              ? AppColors.secondaryDark
                              : AppColors.statusRed,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('d/M').format(s.snapshotAt),
                        style: AppTextStyles.receiptSmall.copyWith(
                          fontSize: 8,
                          color: AppColors.paperInkSoft,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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
            Icon(Icons.bar_chart_rounded,
                size: 72, color: AppColors.brand.withValues(alpha: 0.25)),
            const SizedBox(height: AppDimensions.space16),
            Text('Sin datos todavía',
                style: AppTextStyles.headlineMedium.copyWith(color: AppColors.brand)),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Finaliza tu primer turno para ver reportes aquí.',
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
