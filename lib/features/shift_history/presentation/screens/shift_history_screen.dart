import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/receipt_widgets.dart';
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
    final profit = snapshot.netProfit;
    final profitColor =
        profit >= 0 ? AppColors.secondaryDark : AppColors.statusRed;

    return ReceiptStub(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('TURNO #$index',
                  style: AppTextStyles.receiptBodyBold
                      .copyWith(color: AppColors.paperInk)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.paperInkSoft),
            ],
          ),
          Text(
            dateFormat.format(snapshot.snapshotAt),
            style: AppTextStyles.receiptSmall.copyWith(color: AppColors.paperInkSoft),
          ),
          const DashedDivider(padding: EdgeInsets.symmetric(vertical: 6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(label: 'DEUDA', value: snapshot.totalDebt.toCop),
              _MiniStat(label: 'EFECTIVO', value: snapshot.cashInHand.toCop),
              _MiniStat(
                label: 'UTILIDAD',
                value: profit.toSignedCop,
                color: profitColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.receiptSmall
                .copyWith(color: AppColors.paperInkSoft, fontSize: 9)),
        Text(
          value,
          style: AppTextStyles.receiptBodyBold
              .copyWith(color: color ?? AppColors.paperInk, fontSize: 12.5),
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
