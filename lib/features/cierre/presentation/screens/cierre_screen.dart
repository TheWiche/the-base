import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Cierre Blindado — the daily shift-close screen.
///
/// ── Guard logic ───────────────────────────────────────────────────────────────
/// [cierreValidationProvider] computes the list of [CierreBlocker]s reactively.
/// While any blocker exists, "FINALIZAR JORNADA" is disabled and the screen
/// renders the exact list of what must be resolved first.
///
/// ── Net Profit calculation ────────────────────────────────────────────────────
/// When all blockers are cleared the screen switches to the profit calculator:
///   • Waiter enters physical cash in hand.
///   • Net Profit = Cash in Hand − Total Debt + Transfer Tips
///   • Figures come from [enrichedWalletSummaryProvider].
/// COP bill and coin denominations, largest first, for the cash counter.
const List<int> _copDenominations = [
  100000, 50000, 20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50,
];

/// Formats an integer with '.' thousands separators (Colombian style).
String _formatThousands(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

class CierreScreen extends ConsumerStatefulWidget {
  const CierreScreen({super.key});

  @override
  ConsumerState<CierreScreen> createState() => _CierreScreenState();
}

class _CierreScreenState extends ConsumerState<CierreScreen> {
  final _cashController = TextEditingController();
  int _cashInHand = 0;

  /// denomination (COP) → count, persisted while the screen is open so the
  /// waiter can reopen the counter without losing their tally.
  final Map<int, int> _denomCounts = {};

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  /// Opens the bill/coin counter. The resulting total feeds both the cash field
  /// and [_cashInHand] so the net-profit math and the share summary are unchanged.
  Future<void> _openCashCounter() async {
    final result = await showModalBottomSheet<Map<int, int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CashCounterSheet(initialCounts: _denomCounts),
    );
    if (result == null || !mounted) return;

    _denomCounts
      ..clear()
      ..addAll(result);
    final total = result.entries
        .fold(0, (sum, e) => sum + e.key * e.value);
    setState(() {
      _cashInHand = total;
      _cashController.text = _formatThousands(total);
    });
  }

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
          ) ?? const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.badgePaddingH,
                vertical: AppDimensions.badgePaddingV,
              ),
              decoration: BoxDecoration(
                color: validation.canClose
                    ? AppColors.statusGreen.withOpacity(0.15)
                    : AppColors.statusRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: validation.canClose
                      ? AppColors.statusGreen.withOpacity(0.5)
                      : AppColors.statusRed.withOpacity(0.5),
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
              // ── Blocker list ───────────────────────────────────────
              _BlockerHeader(count: validation.blockers.length),
              const SizedBox(height: AppDimensions.space16),
              ...validation.blockers.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                  child: _BlockerCard(blocker: b),
                ),
              ),
              const SizedBox(height: AppDimensions.space32),
            ],

            if (validation.canClose) ...[
              // ── Net Profit calculator ──────────────────────────────
              _ClearStateHeader(),
              const SizedBox(height: AppDimensions.space24),
              walletAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
                  e.toString(),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.statusRed),
                ),
                data: (summary) => _ProfitCalculator(
                  summary: summary,
                  cashInHand: _cashInHand,
                  controller: _cashController,
                  onCashChanged: (value) =>
                      setState(() => _cashInHand = value),
                  onOpenCounter: _openCashCounter,
                ),
              ),
              const SizedBox(height: AppDimensions.space32),
            ],

            // ── Finalizar Jornada button ───────────────────────────
            _FinalizarButton(
              canClose: validation.canClose,
              cashDeclared: _cashInHand > 0,
              onPressed: (validation.canClose && _cashInHand > 0)
                  ? _showFinalizarDialog
                  : null,
            ),
            const SizedBox(height: AppDimensions.space32),
          ],
        ),
      ),
    );
  }

  void _shareShift(WalletSummary summary) {
    final netProfit = _cashInHand - summary.totalDebt + summary.transferTipsTotal;
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final lines = [
      '📊 Resumen de Turno — $dateStr',
      '──────────────────────────────',
      'Deuda Total:          ${summary.totalDebt.toCop}',
      'Transferencias:       ${summary.verifiedTransfersTotal.toCop}',
      if (summary.transferTipsTotal > 0)
        'Propinas (transfer.): ${summary.transferTipsTotal.toCop}',
      'Efectivo en Mano:     ${_cashInHand.toCop}',
      '──────────────────────────────',
      'UTILIDAD NETA:        ${netProfit.toSignedCop}',
      '',
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

    final today      = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final mesasHoy   = closedSessions
        .where((s) => s.openedAt.isAfter(startOfDay))
        .length;

    final incrementCount = summary.transactions
        .where((t) => t.type == TransactionType.increase)
        .length;

    final netProfit = _cashInHand - summary.totalDebt + summary.transferTipsTotal;

    showDialog<void>(
      context: context,
      builder: (ctx) => _CierreResumenDialog(
        totalDebt:       summary.totalDebt,
        totalLiquorDebt: summary.totalLiquorDebt,
        verifiedTransfers: summary.verifiedTransfersTotal,
        cashPayments:    summary.cashPaymentsTotal,
        transferTips:    summary.transferTipsTotal,
        cashInHand:      _cashInHand,
        netProfit:       netProfit,
        mesasAtendidas:  mesasHoy,
        incrementCount:  incrementCount,
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
    if (summary == null || !mounted) return;

    final result = await ref.read(finalizeShiftUseCaseProvider).call(
          summary: summary,
          cashInHand: _cashInHand,
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

    AppToast.success(context, 'Jornada finalizada. ¡Hasta mañana!');
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
        color: AppColors.statusRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.statusRed.withOpacity(0.3)),
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
                  'Cierre Bloqueado',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // (ícono, título, detalle, color, ruta para resolver, ¿push?)
    final (icon, title, detail, color, route, usePush) = switch (blocker) {
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

    // Tarjeta suave (fondo tintado) y navegable: tap → ir a resolver.
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      onTap: () => usePush ? context.push(route) : context.go(route),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.10 : 0.07),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: color.withOpacity(0.30), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: AppDimensions.tapTargetStd,
              height: AppDimensions.tapTargetStd,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: AppDimensions.iconLg),
            ),
            const SizedBox(width: AppDimensions.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(color: color),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    detail,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.warning_rounded,
                color: color.withOpacity(0.7), size: AppDimensions.iconSm),
            const SizedBox(width: AppDimensions.space4),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  String _buildTablesDetail(List<TableSessionEntity> sessions) {
    final labels = sessions.map((s) => s.shortLabel).toList();
    if (labels.length <= 3) return labels.join(', ') + ' aún activa(s).';
    final shown = labels.take(3).join(', ');
    return '$shown y ${labels.length - 3} más activa(s).';
  }
}

// ── Clear state header ─────────────────────────────────────────────────────────

class _ClearStateHeader extends StatelessWidget {
  const _ClearStateHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.statusGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.statusGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.statusGreen, size: AppDimensions.iconLg),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todo en orden',
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: AppColors.statusGreen),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  'Ingresa el efectivo en mano para ver la utilidad neta.',
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

// ── Net Profit calculator ─────────────────────────────────────────────────────

class _ProfitCalculator extends StatelessWidget {
  const _ProfitCalculator({
    required this.summary,
    required this.cashInHand,
    required this.controller,
    required this.onCashChanged,
    required this.onOpenCounter,
  });

  final WalletSummary summary;
  final int cashInHand;
  final TextEditingController controller;
  final void Function(int) onCashChanged;
  final VoidCallback onOpenCounter;

  @override
  Widget build(BuildContext context) {
    final netProfit    = cashInHand - summary.totalDebt + summary.transferTipsTotal;
    final isProfitable = netProfit >= 0;
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface;
    final outlineColor = isDark ? AppColors.darkOutlineVariant : AppColors.lightOutlineVariant;
    final mutedColor   = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cash in hand card ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: cashInHand > 0
                  ? AppColors.statusGreen.withOpacity(0.5)
                  : outlineColor,
              width: cashInHand > 0 ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.payments_rounded,
                    size: 16,
                    color: cashInHand > 0 ? AppColors.statusGreen : mutedColor,
                  ),
                  const SizedBox(width: AppDimensions.space6),
                  Text(
                    'EFECTIVO EN MANO',
                    style: AppTextStyles.statusBadge.copyWith(
                      color: cashInHand > 0 ? AppColors.statusGreen : mutedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space12),
              TextFormField(
                controller: controller,
                autofocus: false,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandsSeparatorFormatter(),
                ],
                style: AppTextStyles.headlineLarge,
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: AppTextStyles.headlineMedium.copyWith(
                    color: mutedColor,
                  ),
                  hintText: '0',
                  hintStyle: AppTextStyles.headlineLarge.copyWith(
                    color: isDark ? AppColors.darkDisabled : AppColors.lightDisabled,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: (raw) {
                  final digits = raw.replaceAll('.', '');
                  onCashChanged(int.tryParse(digits) ?? 0);
                },
              ),
              const SizedBox(height: AppDimensions.space12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenCounter,
                  icon: const Icon(Icons.calculate_rounded, size: AppDimensions.iconSm),
                  label: const Text('Contar billetera'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.space20),

        // ── Financial summary card ───────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: outlineColor),
          ),
          child: Column(
            children: [
              _SummaryRow(
                label: 'Deuda Total',
                value: summary.totalDebt.toCop,
                valueColor: AppColors.statusRed,
                icon: Icons.receipt_long_rounded,
                isFirst: true,
              ),
              _SummaryDivider(),
              _SummaryRow(
                label: 'Transferencias',
                value: summary.verifiedTransfersTotal.toCop,
                valueColor: AppColors.statusBlue,
                icon: Icons.verified_rounded,
              ),
              if (summary.transferTipsTotal > 0) ...[
                _SummaryDivider(),
                _SummaryRow(
                  label: 'Propinas',
                  value: summary.transferTipsTotal.toCop,
                  valueColor: AppColors.brand,
                  icon: Icons.star_rounded,
                ),
              ],
              _SummaryDivider(),
              _SummaryRow(
                label: 'Efectivo Declarado',
                value: cashInHand.toCop,
                valueColor: AppColors.statusGreen,
                icon: Icons.payments_rounded,
              ),

              // ── Net profit result ──────────────────────────────────
              Divider(
                height: 1,
                thickness: 1,
                color: cashInHand > 0
                    ? (isProfitable
                        ? AppColors.statusGreen.withOpacity(0.3)
                        : AppColors.statusRed.withOpacity(0.3))
                    : outlineColor,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space16,
                ),
                decoration: BoxDecoration(
                  color: cashInHand > 0
                      ? (isProfitable
                          ? AppColors.statusGreen.withOpacity(0.07)
                          : AppColors.statusRed.withOpacity(0.07))
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppDimensions.radiusLg),
                    bottomRight: Radius.circular(AppDimensions.radiusLg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          cashInHand > 0
                              ? (isProfitable
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded)
                              : Icons.calculate_rounded,
                          size: AppDimensions.iconSm,
                          color: cashInHand > 0
                              ? (isProfitable
                                  ? AppColors.statusGreen
                                  : AppColors.statusRed)
                              : mutedColor,
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        Text(
                          'UTILIDAD NETA',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: cashInHand > 0
                                ? (isProfitable
                                    ? AppColors.statusGreen
                                    : AppColors.statusRed)
                                : mutedColor,
                          ),
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        cashInHand > 0 ? netProfit.toSignedCop : '—',
                        key: ValueKey(netProfit),
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: cashInHand > 0
                              ? (isProfitable
                                  ? AppColors.statusGreen
                                  : AppColors.statusRed)
                              : mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Summary row (inside financial card) ──────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    this.isFirst = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: mutedColor),
          const SizedBox(width: AppDimensions.space10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: mutedColor),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppDimensions.space16,
      endIndent: AppDimensions.space16,
      color: isDark ? AppColors.darkOutlineVariant : AppColors.lightOutlineVariant,
    );
  }
}

// ── Finalizar button ──────────────────────────────────────────────────────────

class _FinalizarButton extends StatelessWidget {
  const _FinalizarButton({
    required this.canClose,
    required this.cashDeclared,
    required this.onPressed,
  });

  final bool canClose;
  final bool cashDeclared;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isReady = canClose && cashDeclared;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeightLg,
          child: FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: isReady ? AppColors.statusGreen : null,
              foregroundColor: isReady ? AppColors.onStatusGreen : null,
            ),
            icon: Icon(isReady ? Icons.lock_open_rounded : Icons.lock_rounded),
            label: Text(
              'FINALIZAR JORNADA',
              style: AppTextStyles.labelLarge.copyWith(
                color: isReady ? AppColors.onStatusGreen : null,
              ),
            ),
          ),
        ),
        if (canClose && !cashDeclared) ...[
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Declara el efectivo en mano para continuar',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.statusOrange),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ── Cierre resumen dialog ─────────────────────────────────────────────────────

class _CierreResumenDialog extends StatelessWidget {
  const _CierreResumenDialog({
    required this.totalDebt,
    required this.totalLiquorDebt,
    required this.verifiedTransfers,
    required this.cashPayments,
    required this.transferTips,
    required this.cashInHand,
    required this.netProfit,
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
  final int cashInHand;
  final int netProfit;
  final int mesasAtendidas;
  final int incrementCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final isProfitable = netProfit >= 0;
    final totalBilled  = cashPayments + verifiedTransfers;

    return AlertDialog(
      icon: Icon(
        isProfitable
            ? Icons.emoji_events_rounded
            : Icons.sentiment_neutral_rounded,
        color: isProfitable ? AppColors.brand : AppColors.statusOrange,
        size: AppDimensions.iconXl,
      ),
      title: Text(
        'Resumen de Jornada',
        style: AppTextStyles.headlineSmall,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Stat chips ───────────────────────────────────────────────
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

          // ── Ingresos ─────────────────────────────────────────────────
          _DialogRow(
            label: 'Total Facturado',
            value: totalBilled.toCop,
            valueColor: AppColors.statusGreen,
          ),
          if (cashPayments > 0)
            _DialogRow(
              label: '  · En efectivo',
              value: cashPayments.toCop,
              valueColor: AppColors.statusGreen,
              isSmall: true,
            ),
          if (verifiedTransfers > 0)
            _DialogRow(
              label: '  · Transferencias',
              value: verifiedTransfers.toCop,
              valueColor: AppColors.statusBlue,
              isSmall: true,
            ),
          if (transferTips > 0) ...[
            const SizedBox(height: AppDimensions.space4),
            _DialogRow(
              label: 'Propinas',
              value: transferTips.toCop,
              valueColor: AppColors.brand,
            ),
          ],

          const SizedBox(height: AppDimensions.space8),

          // ── Deuda ────────────────────────────────────────────────────
          _DialogRow(
            label: 'Deuda Total',
            value: totalDebt.toCop,
            valueColor: AppColors.statusRed,
          ),
          if (totalLiquorDebt > 0)
            _DialogRow(
              label: '  · Por licores',
              value: totalLiquorDebt.toCop,
              valueColor: AppColors.statusPurple,
              isSmall: true,
            ),

          const SizedBox(height: AppDimensions.space8),
          _DialogRow(
            label: 'Efectivo en Mano',
            value: cashInHand.toCop,
            valueColor: AppColors.statusGreen,
          ),

          const Divider(height: AppDimensions.space24),

          // ── Resultado ────────────────────────────────────────────────
          _DialogRow(
            label: 'UTILIDAD NETA',
            value: netProfit.toSignedCop,
            valueColor:
                isProfitable ? AppColors.statusGreen : AppColors.statusRed,
            isBold: true,
          ),

          const SizedBox(height: AppDimensions.space20),

          // ── Botones ──────────────────────────────────────────────────
          SizedBox(
            height: AppDimensions.buttonHeightLg,
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusGreen,
                foregroundColor: AppColors.onStatusGreen,
              ),
              child: const Text('CONFIRMAR CIERRE'),
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

// ── Stat chip (count badge) ───────────────────────────────────────────────────

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
          horizontal: AppDimensions.space10, vertical: AppDimensions.space10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.statusBadge.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
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
    required this.valueColor,
    this.isBold = false,
    this.isSmall = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? AppTextStyles.labelLarge
                : (isSmall
                    ? AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      )
                    : AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      )),
          ),
          Text(
            value,
            style: isBold
                ? AppTextStyles.labelLarge.copyWith(color: valueColor)
                : (isSmall
                    ? AppTextStyles.bodySmall.copyWith(
                        fontSize: 11, color: valueColor)
                    : AppTextStyles.bodyMedium.copyWith(color: valueColor)),
          ),
        ],
      ),
    );
  }
}

// ── Cash counter sheet ────────────────────────────────────────────────────────

class _CashCounterSheet extends StatefulWidget {
  const _CashCounterSheet({required this.initialCounts});

  final Map<int, int> initialCounts;

  @override
  State<_CashCounterSheet> createState() => _CashCounterSheetState();
}

class _CashCounterSheetState extends State<_CashCounterSheet> {
  late final Map<int, int> _counts = {
    for (final d in _copDenominations) d: widget.initialCounts[d] ?? 0,
  };

  int get _total =>
      _counts.entries.fold(0, (sum, e) => sum + e.key * e.value);

  void _set(int denom, int count) =>
      setState(() => _counts[denom] = count < 0 ? 0 : count);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: AppColors.brand),
                  const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: Text('Contar efectivo',
                        style: AppTextStyles.headlineSmall),
                  ),
                ],
              ),
            ),
            const Divider(height: AppDimensions.space24),

            // Denomination rows
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                ),
                itemCount: _copDenominations.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimensions.space8),
                itemBuilder: (_, i) {
                  final denom = _copDenominations[i];
                  final count = _counts[denom] ?? 0;
                  return _CounterRow(
                    denom: denom,
                    count: count,
                    onChanged: (c) => _set(denom, c),
                  );
                },
              ),
            ),

            // Total + apply
            Padding(
              padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL CONTADO',
                          style: AppTextStyles.statusBadge.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.lightOnSurfaceVariant,
                          )),
                      Text(_total.toCop,
                          style: AppTextStyles.headlineMedium
                              .copyWith(color: AppColors.statusGreen)),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightLg,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(_counts),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.statusGreen,
                        foregroundColor: AppColors.onStatusGreen,
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        'Usar este total',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.onStatusGreen),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.denom,
    required this.count,
    required this.onChanged,
  });

  final int denom;
  final int count;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtotal = denom * count;
    final isCoin = denom < 1000;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: count > 0
              ? AppColors.brand.withOpacity(0.4)
              : (isDark ? AppColors.darkOutlineVariant : AppColors.lightOutlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCoin ? Icons.toll_rounded : Icons.payments_rounded,
            size: AppDimensions.iconSm,
            color: count > 0 ? AppColors.brand : AppColors.darkDisabled,
          ),
          const SizedBox(width: AppDimensions.space8),
          // Denomination + running subtotal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\$ ${_formatThousands(denom)}',
                    style: AppTextStyles.titleMedium),
                if (count > 0)
                  Text(subtotal.toCop,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.statusGreen)),
              ],
            ),
          ),
          // Stepper
          IconButton(
            onPressed: count > 0 ? () => onChanged(count - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: AppColors.brand,
          ),
          SizedBox(
            width: 28,
            child: Text('$count',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall),
          ),
          IconButton(
            onPressed: () => onChanged(count + 1),
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppColors.brand,
          ),
        ],
      ),
    );
  }
}

// ── Thousands separator formatter ─────────────────────────────────────────────

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(digits);
    if (number == null) return oldValue;
    final formatted = _format(number);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
