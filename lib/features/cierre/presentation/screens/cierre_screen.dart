import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/services/table_counter_service.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../base_management/domain/entities/base_transaction_entity.dart';
import '../../../base_management/domain/entities/wallet_summary.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../tables/domain/entities/table_session_entity.dart';
import '../../domain/entities/cierre_blocker.dart';
import '../providers/cierre_providers.dart';

/// Cierre Blindado — Pantalla de Cierre de Jornada.
///
/// ── Cierre Blindado ──────────────────────────────────────────────────────────
/// [cierreValidationProvider] computa la lista de [CierreBlocker]s reactivamente:
///   1. Ítems pendientes en El Radar.
///   2. Mesas abiertas con saldo pendiente.
///   3. Transferencias sin legalizar en caja.
/// Mientras exista cualquier bloqueo, el cierre permanece bloqueado.
///
/// ── Cierre Directo ──────────────────────────────────────────────────────────
/// Una vez superadas las condiciones de Cierre Blindado, el cierre es directo con
/// el botón "Finalizar Jornada", sin conteos de efectivo ni pasos redundantes.
class CierreScreen extends ConsumerStatefulWidget {
  const CierreScreen({super.key});

  @override
  ConsumerState<CierreScreen> createState() => _CierreScreenState();
}

class _CierreScreenState extends ConsumerState<CierreScreen> {
  @override
  Widget build(BuildContext context) {
    final validation = ref.watch(cierreValidationProvider);
    final walletAsync = ref.watch(enrichedWalletSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cierre del Día', style: AppTextStyles.headlineSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.work_history_rounded),
            tooltip: 'Historial de turnos',
            onPressed: () => context.push('/cierre/historial'),
          ),
          walletAsync.whenOrNull(
                data: (summary) => IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Exportar turno',
                  onPressed: () => _shareShift(summary),
                ),
              ) ??
              const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.badgePaddingH,
                vertical: AppDimensions.badgePaddingV,
              ),
              decoration: BoxDecoration(
                color: validation.canClose
                    ? AppColors.statusGreen.withValues(alpha: 0.15)
                    : AppColors.statusRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: validation.canClose
                      ? AppColors.statusGreen.withValues(alpha: 0.5)
                      : AppColors.statusRed.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    validation.canClose
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    size: 14,
                    color: validation.canClose
                        ? AppColors.statusGreen
                        : AppColors.statusRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    validation.canClose ? 'LIBRE' : 'BLOQUEADO',
                    style: AppTextStyles.statusBadge.copyWith(
                      color: validation.canClose
                          ? AppColors.statusGreen
                          : AppColors.statusRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!validation.canClose) ...[
              // ── Lista de bloqueos activos (Cierre Blindado) ─────────
              _BlockerHeader(count: validation.blockers.length),
              const SizedBox(height: AppDimensions.space16),
              ...validation.blockers.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                  child: _BlockerCard(blocker: b),
                ),
              ),
              const SizedBox(height: AppDimensions.space24),
            ],

            if (validation.canClose) ...[
              // ── Estado desbloqueado + Resumen del turno ─────────────
              const _ClearStateHeader(),
              const SizedBox(height: AppDimensions.space20),
              walletAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
                  e.toString(),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.statusRed),
                ),
                data: (summary) => _ShiftOverviewCard(summary: summary),
              ),
              const SizedBox(height: AppDimensions.space24),
            ],

            // ── Botón Finalizar Jornada ─────────────────────────────
            _FinalizarButton(
              canClose: validation.canClose,
              onPressed: validation.canClose ? _showFinalizarDialog : null,
            ),
            const SizedBox(height: AppDimensions.space32),
          ],
        ),
      ),
    );
  }

  void _shareShift(WalletSummary summary) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final lines = [
      '📊 Resumen de Turno — $dateStr',
      '──────────────────────────────',
      'Deuda Total:          ${summary.totalDebt.toCop}',
      'Total Vendido:        ${summary.totalSold.toCop}',
      '  · Ventas en Efectivo: ${summary.cashPaymentsTotal.toCop}',
      '  · Transferencias:     ${summary.verifiedTransfersTotal.toCop}',
      if (summary.standaloneTransfersTotal > 0)
        '  · Sueltas (registro): ${summary.standaloneTransfersTotal.toCop}',
      if (summary.transferTipsTotal > 0)
        'Propinas (transfer.): ${summary.transferTipsTotal.toCop}',
      'Saldo Disponible:     ${summary.availableBalance.toCop}',
      '──────────────────────────────',
      'Generado con The Base 🍺',
    ];
    Share.share(lines.join('\n'), subject: 'Resumen de Turno — $dateStr');
  }

  Future<void> _showFinalizarDialog() async {
    final walletAsync = ref.read(enrichedWalletSummaryProvider);
    final summary = walletAsync.valueOrNull;
    if (summary == null) return;

    final closedSessions = await ref.read(closedSessionsProvider.future);
    if (!mounted) return;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final mesasHoy =
        closedSessions.where((s) => s.openedAt.isAfter(startOfDay)).length;

    final incrementCount = summary.transactions
        .where((t) => t.type == TransactionType.increase)
        .length;

    showDialog<void>(
      context: context,
      builder: (ctx) => _CierreResumenDialog(
        totalDebt: summary.totalDebt,
        totalLiquorDebt: summary.totalLiquorDebt,
        verifiedTransfers: summary.verifiedTransfersTotal,
        cashPayments: summary.cashPaymentsTotal,
        transferTips: summary.transferTipsTotal,
        mesasAtendidas: mesasHoy,
        incrementCount: incrementCount,
        onConfirm: () {
          Navigator.of(ctx).pop();
          _onCierreConfirmed();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _onCierreConfirmed() async {
    final summary = ref.read(enrichedWalletSummaryProvider).valueOrNull;
    if (summary == null || !summary.hasInitialBase || !mounted) return;

    final expectedCash = summary.expectedCashInHand;
    final result = await ref.read(finalizeShiftUseCaseProvider).call(
          summary: summary.copyWith(physicalCashInHand: expectedCash),
          cashInHand: expectedCash,
        );
    if (!mounted) return;

    if (result.isErr) {
      AppToast.error(
          context, 'Error al finalizar: ${(result as Err).failure.message}');
      return;
    }

    // Reinicia la numeración de mesas: el próximo turno arranca en Mesa 1.
    await TableCounterService().reset();
    if (!mounted) return;

    AppToast.success(context, 'Jornada finalizada con éxito. ¡Hasta el próximo turno!');
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) context.go('/');
  }
}

// ── Blocker header ────────────────────────────────────────────────────────────

class _BlockerHeader extends StatelessWidget {
  const _BlockerHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.statusRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.statusRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block_rounded,
              color: AppColors.statusRed, size: AppDimensions.iconLg),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cierre Bloqueado (Cierre Blindado)',
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: AppColors.statusRed),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  '$count ${count == 1 ? 'condición' : 'condiciones'} '
                  'deben resolverse antes de finalizar la jornada.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Blocker card ──────────────────────────────────────────────────────────────

class _BlockerCard extends StatelessWidget {
  const _BlockerCard({required this.blocker});

  final CierreBlocker blocker;

  @override
  Widget build(BuildContext context) {
    final (icon, title, detail, color, route, usePush) = switch (blocker) {
      NoShiftInitializedBlocker() => (
          Icons.account_balance_wallet_rounded,
          'Jornada No Iniciada o Sin Movimientos',
          'La jornada no ha sido iniciada previamente o no registra movimientos válidos. Ve a Billetera para iniciar turno.',
          AppColors.statusOrange,
          '/base',
          false,
        ),
      PendingRadarBlocker(:final count) => (
          Icons.radar_rounded,
          'Pedidos Pendientes en el Radar',
          '$count ${count == 1 ? 'ítem pendiente' : 'ítems pendientes'} sin entregar.',
          AppColors.statusOrange,
          '/radar',
          false,
        ),
      OpenTablesBlocker(:final sessions) => (
          Icons.table_restaurant_rounded,
          'Mesas con Saldo Pendiente',
          _buildTablesDetail(sessions),
          AppColors.statusRed,
          '/tables',
          false,
        ),
      UnlegalizedTransfersBlocker(:final count, :final totalPending) => (
          Icons.smartphone_rounded,
          'Transferencias sin Legalizar',
          '$count ${count == 1 ? 'transferencia' : 'transferencias'} '
              '(${totalPending.toCop}) sin verificar en caja.',
          AppColors.statusBlue,
          '/legalizacion',
          true,
        ),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
      onTap: () => usePush ? context.push(route) : context.go(route),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: AppDimensions.iconLg),
            const SizedBox(width: AppDimensions.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    detail,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  String _buildTablesDetail(List<TableSessionEntity> sessions) {
    if (sessions.isEmpty) return '0 mesas abiertas.';
    final numbers = sessions.map((s) => 'Mesa ${s.tableNumber}').join(', ');
    return '${sessions.length} ${sessions.length == 1 ? 'mesa abierta' : 'mesas abiertas'}: $numbers.';
  }
}

// ── Clear state header ────────────────────────────────────────────────────────

class _ClearStateHeader extends StatelessWidget {
  const _ClearStateHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.statusGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(color: AppColors.statusGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.statusGreen,
            size: AppDimensions.iconLg,
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cierre Desbloqueado',
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: AppColors.statusGreen),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  'Sin pedidos pendientes, mesas abiertas ni transferencias sin legalizar.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de Resumen Financiero del Turno ───────────────────────────────────

class _ShiftOverviewCard extends StatelessWidget {
  const _ShiftOverviewCard({required this.summary});

  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final totalFacturado = summary.totalSold;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'RESUMEN FINANCIERO DEL TURNO',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),

          _OverviewRow(
            label: 'Total Facturado',
            value: totalFacturado.toCop,
            valueColor: AppColors.statusGreen,
            isBold: true,
          ),
          _OverviewRow(
            label: '  · Ventas en efectivo',
            value: summary.cashPaymentsTotal.toCop,
            isSmall: true,
          ),
          _OverviewRow(
            label: '  · Ventas transferencias (mesas)',
            value: summary.verifiedTransfersTotal.toCop,
            isSmall: true,
          ),
          if (summary.standaloneTransfersTotal > 0)
            _OverviewRow(
              label: '  · Comprobantes sueltos (auditoría)',
              value: summary.standaloneTransfersTotal.toCop,
              valueColor: AppColors.statusBlue,
              isSmall: true,
            ),
          if (summary.transferTipsTotal > 0)
            _OverviewRow(
              label: '  · Propinas recibidas',
              value: summary.transferTipsTotal.toCop,
              valueColor: AppColors.primary,
              isSmall: true,
            ),

          const SizedBox(height: 10),
          Divider(height: 1, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 10),

          _OverviewRow(
            label: 'Deuda Total con Caja',
            value: summary.totalDebt.toCop,
            valueColor: AppColors.statusRed,
            isBold: true,
          ),
          _OverviewRow(
            label: '  · Base inicial',
            value: summary.initialBase.toCop,
            isSmall: true,
          ),
          if (summary.totalIncreases > 0)
            _OverviewRow(
              label: '  · Subidas de base',
              value: summary.totalIncreases.toCop,
              isSmall: true,
            ),
          if (summary.totalDecreases > 0)
            _OverviewRow(
              label: '  · Descargas a caja',
              value: '-${summary.totalDecreases.toCop}',
              isSmall: true,
            ),
          if (summary.totalLiquorDebt > 0)
            _OverviewRow(
              label: '  · Licores despachados',
              value: summary.totalLiquorDebt.toCop,
              valueColor: summary.totalLiquorDebt > 0 ? AppColors.statusPurple : null,
              isSmall: true,
            ),

          const SizedBox(height: 10),
          Divider(height: 1, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 10),

          _OverviewRow(
            label: 'Efectivo Esperado en Mano',
            value: summary.expectedCashInHand.toCop,
            valueColor: summary.expectedCashInHand >= 0
                ? AppColors.statusGreen
                : AppColors.statusRed,
            isBold: true,
          ),
          _OverviewRow(
            label: '  · Saldo disponible billetera',
            value: summary.availableBalance.toCop,
            isSmall: true,
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.isSmall = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isSmall
                ? AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : (isBold
                    ? AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      )
                    : AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
          ),
          Text(
            value,
            style: isSmall
                ? AppTextStyles.monoSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  )
                : (isBold
                    ? AppTextStyles.monoLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                      )
                    : AppTextStyles.monoMedium.copyWith(
                        color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      )),
          ),
        ],
      ),
    );
  }
}

// ── Botón Finalizar Jornada ───────────────────────────────────────────────────

class _FinalizarButton extends StatelessWidget {
  const _FinalizarButton({
    required this.canClose,
    required this.onPressed,
  });

  final bool canClose;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeightMd,
          child: FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor:
                  canClose ? AppColors.statusGreen : Theme.of(context).colorScheme.outline,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.buttonRadius),
              ),
            ),
            icon: Icon(
              canClose ? Icons.check_circle_rounded : Icons.lock_rounded,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              'FINALIZAR JORNADA',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: 15,
              ),
            ),
          ),
        ),
        if (!canClose) ...[
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Resuelve los bloqueos antes de finalizar la jornada',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.statusOrange),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ── Diálogo de confirmación del Cierre ─────────────────────────────────────────

class _CierreResumenDialog extends StatelessWidget {
  const _CierreResumenDialog({
    required this.totalDebt,
    required this.totalLiquorDebt,
    required this.verifiedTransfers,
    required this.cashPayments,
    required this.transferTips,
    required this.mesasAtendidas,
    required this.incrementCount,
    required this.onConfirm,
    required this.onCancel,
  });

  final int totalDebt;
  final int totalLiquorDebt;
  final int verifiedTransfers;
  final int cashPayments;
  final int transferTips;
  final int mesasAtendidas;
  final int incrementCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalBilled = cashPayments + verifiedTransfers;

    return AlertDialog(
      icon: const Icon(
        Icons.verified_rounded,
        color: AppColors.statusGreen,
        size: AppDimensions.iconXl,
      ),
      title: Text(
        'Confirmar Cierre de Jornada',
        style: AppTextStyles.headlineSmall,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.table_restaurant_rounded,
                  label: 'Mesas',
                  value: '$mesasAtendidas',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: _StatChip(
                  icon: Icons.trending_up_rounded,
                  label: 'Subidas base',
                  value: '$incrementCount',
                  color: AppColors.brand,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.space12),

          _DialogRow(
            label: 'Total Facturado',
            value: totalBilled.toCop,
            valueColor: AppColors.statusGreen,
            isBold: true,
          ),
          if (cashPayments > 0)
            _DialogRow(
              label: '  · Efectivo',
              value: cashPayments.toCop,
              isSmall: true,
            ),
          if (verifiedTransfers > 0)
            _DialogRow(
              label: '  · Transferencias',
              value: verifiedTransfers.toCop,
              isSmall: true,
            ),
          if (transferTips > 0) ...[
            const SizedBox(height: AppDimensions.space4),
            _DialogRow(
              label: 'Propinas',
              value: transferTips.toCop,
              valueColor: AppColors.brand,
              isSmall: true,
            ),
          ],

          const SizedBox(height: AppDimensions.space8),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.space8),

          _DialogRow(
            label: 'Deuda a Rendir en Caja',
            value: totalDebt.toCop,
            valueColor: AppColors.statusRed,
            isBold: true,
          ),
          if (totalLiquorDebt > 0)
            _DialogRow(
              label: '  · Por licores',
              value: totalLiquorDebt.toCop,
              valueColor: AppColors.statusPurple,
              isSmall: true,
            ),

          const SizedBox(height: AppDimensions.space20),

          SizedBox(
            height: AppDimensions.buttonHeightLg,
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusGreen,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'FINALIZAR JORNADA',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          TextButton(
            onPressed: onCancel,
            child: const Text('Revisar'),
          ),
        ],
      ),
      actions: const [],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space10,
        vertical: AppDimensions.space10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogRow extends StatelessWidget {
  const _DialogRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.isSmall = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 1 : 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isSmall
                ? AppTextStyles.bodySmall
                : (isBold
                    ? AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold)
                    : AppTextStyles.bodyMedium),
          ),
          Text(
            value,
            style: isSmall
                ? AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  )
                : (isBold
                    ? AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      )
                    : AppTextStyles.bodyMedium.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w600,
                      )),
          ),
        ],
      ),
    );
  }
}
