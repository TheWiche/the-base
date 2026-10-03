import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/base_transaction_entity.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/settings/financial_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/animated_amount.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/wallet_summary.dart';
import '../providers/base_wallet_providers.dart';
import '../widgets/financial_metric_card.dart';
import '../widgets/incremento_button.dart';
import '../widgets/transaction_log_tile.dart';

/// The waiter's financial home screen — their primary reference point for the shift.
///
/// ── Three render states ───────────────────────────────────────────────────────
///   1. Loading  → spinner while Isar hydrates on first launch.
///   2. No-shift → "Iniciar Turno" prompt when no initial base exists.
///   3. Active   → full dashboard with metrics, CTA, and transaction log.
///
/// ── Interaction model ─────────────────────────────────────────────────────────
/// All write actions go through [BaseWalletNotifier]. Results are surfaced as
/// SnackBars. The Isar reactive stream automatically refreshes the UI.
class BaseWalletScreen extends ConsumerStatefulWidget {
  const BaseWalletScreen({super.key});

  @override
  ConsumerState<BaseWalletScreen> createState() => _BaseWalletScreenState();
}

class _BaseWalletScreenState extends ConsumerState<BaseWalletScreen> {
  bool _isActionLoading = false;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _handleIniciarTurno() async {
    final amount = ref.read(financialSettingsProvider).baseAmount;
    setState(() => _isActionLoading = true);
    final failure =
        await ref.read(baseWalletProvider.notifier).initializeShift();
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (failure != null) {
      _showError(failure.message);
    } else {
      _showSuccess('Turno iniciado. Base: ${amount.toCop}');
    }
  }

  Future<void> _handleRequestIncrease() async {
    final amount = ref.read(financialSettingsProvider).incrementStep;
    final confirmed = await _showIncreaseConfirmation(amount);
    if (!confirmed || !mounted) return;

    setState(() => _isActionLoading = true);
    final failure =
        await ref.read(baseWalletProvider.notifier).requestIncrease();
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (failure != null) {
      _showError(failure.message);
    } else {
      _showSuccess('Incremento registrado: +${amount.toCop}');
    }
  }

  Future<void> _handleRequestDecrease() async {
    final summary = ref.read(baseWalletProvider).valueOrNull;
    final maxAllowed = summary?.netIncreases ?? 0;
    if (maxAllowed <= 0) {
      _showError('No tienes incrementos registrados para descargar.');
      return;
    }

    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DecreaseBaseSheet(maxAllowed: maxAllowed),
    );

    if (amount == null || amount <= 0 || !mounted) return;

    setState(() => _isActionLoading = true);
    final failure = await ref
        .read(baseWalletProvider.notifier)
        .requestDecrease(amount: amount);
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (failure != null) {
      _showError(failure.message);
    } else {
      _showSuccess('Reducción registrada: −${amount.toCop}');
    }
  }

  Future<void> _handleSettleLiquorDebt() async {
    final summary = ref.read(baseWalletProvider).valueOrNull;
    if (summary == null || summary.totalLiquorDebt <= 0) {
      _showError('No tienes deuda de licor pendiente por liquidar.');
      return;
    }

    final result = await showModalBottomSheet<_LiquorSettlementResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SettleLiquorSheet(summary: summary),
    );

    if (result == null || result.amount <= 0 || !mounted) return;

    setState(() => _isActionLoading = true);
    final failure = await ref
        .read(baseWalletProvider.notifier)
        .recordLiquorSettlement(amount: result.amount, note: result.note);
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (failure != null) {
      _showError(failure.message);
    } else {
      _showSuccess(
        'Pago en caja registrado: −${result.amount.toCop}. Deuda de licor actualizada.',
      );
    }
  }

  Future<bool> _showIncreaseConfirmation(int amount) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _IncreaseConfirmationDialog(
            amount: amount,
            onConfirm: () => Navigator.of(ctx).pop(true),
            onCancel: () => Navigator.of(ctx).pop(false),
          ),
        ) ??
        false;
  }

  void _showSuccess(String message) => AppToast.success(context, message);

  void _showError(String message) => AppToast.error(context, message);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Enriched summary includes verified transfers, tips, and served item totals
    // so Available Balance and Net Profit reflect real payment data.
    final walletAsync = ref.watch(enrichedWalletSummaryProvider);
    final financial = ref.watch(financialSettingsProvider);

    return Scaffold(
      body: walletAsync.when(
        loading: () => const _LoadingBody(),
        error: (error, _) => _ErrorBody(
          message: error.toString(),
          onRetry: () => ref.invalidate(baseWalletProvider),
        ),
        data: (summary) => summary.hasInitialBase
            ? _ActiveDashboard(
                summary: summary,
                isActionLoading: _isActionLoading,
                incrementStep: financial.incrementStep,
                onRequestIncrease: _handleRequestIncrease,
                onRequestDecrease: _handleRequestDecrease,
                onSettleLiquorDebt: _handleSettleLiquorDebt,
              )
            : _NoShiftBody(
                isLoading: _isActionLoading,
                baseAmount: financial.baseAmount,
                onIniciarTurno: _handleIniciarTurno,
              ),
      ),
    );
  }
}

// ── Loading state ──────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.brand),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.statusRed, size: 64),
            const SizedBox(height: AppDimensions.space16),
            Text(AppStrings.errorGeneric,
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.space8),
            Text(message,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.space24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(AppStrings.actionRetry),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No-shift state ─────────────────────────────────────────────────────────────

class _NoShiftBody extends StatelessWidget {
  const _NoShiftBody({
    required this.isLoading,
    required this.baseAmount,
    required this.onIniciarTurno,
  });

  final bool isLoading;
  final int baseAmount;
  final VoidCallback onIniciarTurno;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // ── Illustration area ─────────────────────────────────────
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                size: 64,
              ),
            ),
            const SizedBox(height: AppDimensions.space24),
            Text(
              'Sin turno activo',
              style: AppTextStyles.headlineLarge.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Inicia tu turno para activar la billetera y comenzar a tomar pedidos.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // ── Iniciar turno CTA ─────────────────────────────────────
            IniciarTurnoButton(
              isLoading: isLoading,
              amount: baseAmount,
              onPressed: onIniciarTurno,
            ),
            const SizedBox(height: AppDimensions.space24),
          ],
        ),
      ),
    );
  }
}

// ── Active dashboard ───────────────────────────────────────────────────────────

class _ActiveDashboard extends StatefulWidget {
  const _ActiveDashboard({
    required this.summary,
    required this.isActionLoading,
    required this.incrementStep,
    required this.onRequestIncrease,
    required this.onRequestDecrease,
    required this.onSettleLiquorDebt,
  });

  final WalletSummary summary;
  final bool isActionLoading;
  final int incrementStep;
  final VoidCallback onRequestIncrease;
  final VoidCallback onRequestDecrease;
  final VoidCallback onSettleLiquorDebt;

  @override
  State<_ActiveDashboard> createState() => _ActiveDashboardState();
}

class _ActiveDashboardState extends State<_ActiveDashboard>
    with TickerProviderStateMixin {
  int _tabIndex = 0; // 0 = Resumen, 1 = Movimientos
  late final AnimationController _entranceCtrl;
  late final Animation<double> _metricsAnim;
  late final Animation<double> _actionsAnim;
  final _scrollController = ScrollController();

  void _setTab(int i) {
    setState(() => _tabIndex = i);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _metricsAnim = _interval(0.25, 0.80);
    _actionsAnim = _interval(0.45, 1.00);
    _entranceCtrl.forward();
  }

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balanceColor =
        widget.summary.isSolvent ? AppColors.statusGreen : AppColors.statusRed;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // ── Collapsing AppBar with tabs ────────────────────────────────
        SliverAppBar(
          expandedHeight: 266,
          pinned: true,
          stretch: true,
          backgroundColor: AppColors.paperBackground,
          elevation: 0,
          title: Text(
            AppStrings.appTagline,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Reportes',
              icon: const Icon(Icons.bar_chart_rounded, color: AppColors.ink),
              onPressed: () => context.push('/reportes'),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: _WalletHeader(
              summary: widget.summary,
              balanceColor: balanceColor,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(62),
            child: Container(
              color: AppColors.paperBackground,
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePaddingH, 8, AppDimensions.pagePaddingH, 10,
              ),
              child: PillToggle(
                options: const ['Resumen', 'Movimientos'],
                selectedIndex: _tabIndex,
                onChanged: _setTab,
              ),
            ),
          ),
        ),

        // ── Tab content ────────────────────────────────────────────────
        if (_tabIndex == 0) ...[
          // ── Resumen: metrics ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _metricsAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(_metricsAnim),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePaddingH,
                    AppDimensions.space20,
                    AppDimensions.pagePaddingH,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.summary.availableBalance < 0) ...[
                        _NegativeBalanceAlert(
                          onTap: widget.onRequestIncrease,
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],
                      MetricCardRow(
                        left: FinancialMetricCard(
                          label: AppStrings.baseLabel,
                          amount: widget.summary.baseCapital,
                          accentColor: AppColors.brand,
                          icon: Icons.savings_rounded,
                          subtitle: 'Capital comprometido',
                        ),
                        right: FinancialMetricCard(
                          label: 'Deuda Total',
                          amount: widget.summary.totalDebt,
                          accentColor: AppColors.statusRed,
                          icon: Icons.receipt_long_rounded,
                          subtitle: 'Lo que debes al local',
                        ),
                      ),
                      if (widget.summary.totalLiquorDebt > 0) ...[
                        const SizedBox(height: AppDimensions.space12),
                        FinancialMetricCard(
                          label: 'Deuda por Licor',
                          amount: widget.summary.totalLiquorDebt,
                          accentColor: AppColors.statusPurple,
                          icon: Icons.wine_bar_rounded,
                          subtitle: 'Agregado a deuda — no descuenta del saldo',
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        SizedBox(
                          width: double.infinity,
                          height: AppDimensions.buttonHeightMd,
                          child: FilledButton.icon(
                            onPressed: widget.isActionLoading
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    widget.onSettleLiquorDebt();
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.statusPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.buttonRadius,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.point_of_sale_rounded,
                              size: 20,
                            ),
                            label: const Text(
                              'Pagar / Liquidar Botella en Caja',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Resumen: CTAs ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _actionsAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(_actionsAnim),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePaddingH,
                    AppDimensions.space24,
                    AppDimensions.pagePaddingH,
                    0,
                  ),
                  child: Column(
                    children: [
                      IncrementoButton(
                        isLoading: widget.isActionLoading,
                        isEnabled: widget.summary.canRequestIncrease,
                        amount: widget.incrementStep,
                        onPressed: widget.onRequestIncrease,
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      _DecrementoButton(
                        isLoading: widget.isActionLoading,
                        isEnabled: widget.summary.canRequestDecrease,
                        onPressed: widget.onRequestDecrease,
                      ),
                      const SizedBox(height: AppDimensions.space64),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          // ── Movimientos: transaction log ─────────────────────────────
          if (widget.summary.sortedTransactions.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: AppDimensions.space32),
                child: _EmptyTransactions(),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePaddingH,
                  AppDimensions.space20,
                  AppDimensions.pagePaddingH,
                  AppDimensions.space8,
                ),
                child: Text(
                  '${widget.summary.transactions.length} movimiento(s) en este turno',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePaddingH,
                0,
                AppDimensions.pagePaddingH,
                AppDimensions.space64,
              ),
              sliver: SliverList.builder(
                itemCount: widget.summary.sortedTransactions.length,
                itemBuilder: (context, index) {
                  final tx = widget.summary.sortedTransactions[index];
                  return TransactionLogTile(
                    transaction: tx,
                    showDivider:
                        index < widget.summary.sortedTransactions.length - 1,
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ── Wallet header (AppBar expanded content) ────────────────────────────────────

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({
    required this.summary,
    required this.balanceColor,
  });

  final WalletSummary summary;
  final Color balanceColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.paperSurface, AppColors.paperBackground],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.paperBorder, width: 1.0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        MediaQuery.of(context).padding.top + AppDimensions.space48,
        AppDimensions.pagePaddingH,
        AppDimensions.space64,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ── Saldo disponible hero ──────────────────────────────────
          Text(
            'SALDO DISPONIBLE',
            style: AppTextStyles.statusBadge.copyWith(
              color: AppColors.inkSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AnimatedAmount(
                  amount: summary.availableBalance,
                  style: AppTextStyles.receiptTotal.copyWith(
                    fontSize: 36,
                    color: summary.isSolvent ? AppColors.ink : AppColors.statusRed,
                  ),
                  duration: const Duration(milliseconds: 700),
                ),
              ),
              _SolvencyBadge(isSolvent: summary.isSolvent),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Turno activo • ${summary.transactions.length} movimientos',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Solvency status badge ──────────────────────────────────────────────────────

class _SolvencyBadge extends StatelessWidget {
  const _SolvencyBadge({required this.isSolvent});

  final bool isSolvent;

  @override
  Widget build(BuildContext context) {
    final color = isSolvent ? AppColors.statusGreen : AppColors.statusRed;
    final label = isSolvent ? 'POSITIVO' : 'EN DEUDA';
    final icon = isSolvent
        ? Icons.check_circle_rounded
        : Icons.warning_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.statusBadge.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty transaction state ────────────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space48),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: AppDimensions.iconXl,
            color: AppColors.inkSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.space12),
          Text(
            'Sin movimientos aún',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.inkSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Negative Balance Alert ───────────────────────────────────────────────────

class _NegativeBalanceAlert extends StatelessWidget {
  const _NegativeBalanceAlert({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.space12),
          decoration: BoxDecoration(
            color: AppColors.statusRed.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: AppColors.statusRed.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.space8),
                decoration: BoxDecoration(
                  color: AppColors.statusRed.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.statusRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Negativo',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.statusRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '¿Subiste de base en caja y olvidaste anotarla? Toca aquí para registrar aumento',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.statusRed,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.statusRed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Decrement button ───────────────────────────────────────────────────────────

class _DecrementoButton extends StatelessWidget {
  const _DecrementoButton({
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightMd,
      child: AnimatedOpacity(
        opacity: canTap ? 1.0 : 0.38,
        duration: const Duration(milliseconds: 200),
        child: OutlinedButton.icon(
          onPressed: canTap
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed();
                }
              : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: canTap
                  ? AppColors.statusOrange
                  : AppColors.statusOrange.withValues(alpha: 0.4),
              width: 1.5,
            ),
            foregroundColor: AppColors.statusOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.statusOrange,
                    ),
                  ),
                )
              : const Icon(Icons.trending_down_rounded),
          label: Text(
            'BAJAR BASE A CAJA',
            style: AppTextStyles.labelLarge.copyWith(
              color: canTap
                  ? AppColors.statusOrange
                  : AppColors.statusOrange.withValues(alpha: 0.4),
              letterSpacing: 0.8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Increase confirmation dialog ───────────────────────────────────────────────

class _IncreaseConfirmationDialog extends StatelessWidget {
  const _IncreaseConfirmationDialog({
    required this.amount,
    required this.onConfirm,
    required this.onCancel,
  });

  final int amount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return AlertDialog(
      backgroundColor: AppColors.paperSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        side: const BorderSide(color: AppColors.paperBorder),
      ),
      icon: const Icon(
        Icons.trending_up_rounded,
        color: AppColors.primary,
        size: AppDimensions.iconXl,
      ),
      title: Text(
        '¿Confirmar Incremento?',
        style: AppTextStyles.headlineSmall.copyWith(color: AppColors.ink),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Se agregarán ${amount.toCop} a tu base.\nEsta acción quedará registrada con la hora exacta.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.space16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12, vertical: AppDimensions.space10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: AppTextStyles.mono.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          SizedBox(
            height: AppDimensions.buttonHeightMd,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onConfirm();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                ),
              ),
              child: Text(
                AppStrings.actionConfirm,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          TextButton(
            onPressed: onCancel,
            child: Text(
              AppStrings.actionCancel,
              style: TextStyle(color: AppColors.inkSecondary),
            ),
          ),
        ],
      ),
      actions: const [],
    );
  }
}

// ── Decrease Base Bottom Sheet ─────────────────────────────────────────────────

class _DecreaseBaseSheet extends StatefulWidget {
  const _DecreaseBaseSheet({required this.maxAllowed});

  final int maxAllowed;

  @override
  State<_DecreaseBaseSheet> createState() => _DecreaseBaseSheetState();
}

class _DecreaseBaseSheetState extends State<_DecreaseBaseSheet> {
  late final TextEditingController _controller;
  int _amount = 0;

  static const List<int> _quickAmounts = [
    100000,
    200000,
    300000,
    400000,
    500000,
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.maxAllowed >= 100000 ? 100000 : widget.maxAllowed;
    _amount = initial;
    _controller = TextEditingController(text: initial > 0 ? '$initial' : '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectAmount(int val) {
    setState(() {
      _amount = val;
      _controller.text = val.toString();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _amount > 0 && _amount <= widget.maxAllowed;
    final isExceeded = _amount > widget.maxAllowed;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.modalRadius),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.paperBorder, width: 1.0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space16,
        AppDimensions.pagePaddingH,
        AppDimensions.pagePaddingH + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.paperBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space8),
                    decoration: BoxDecoration(
                      color: AppColors.statusOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_down_rounded,
                      color: AppColors.statusOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bajar Base a Caja',
                          style: AppTextStyles.titleLarge.copyWith(color: AppColors.ink),
                        ),
                        Text(
                          'Disponible para bajar: ${widget.maxAllowed.toCop}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),

              // Chips rápidos ($100k, $200k, $300k, $400k, $500k)
              Text(
                'Montos rápidos',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in _quickAmounts)
                    ActionChip(
                      label: Text('\$${q ~/ 1000}k'),
                      avatar: q == _amount
                          ? const Icon(Icons.check_rounded, size: 16)
                          : null,
                      backgroundColor: q == _amount
                          ? AppColors.statusOrange.withValues(alpha: 0.15)
                          : AppColors.paperBackground,
                      side: BorderSide(
                        color: q == _amount
                            ? AppColors.statusOrange
                            : AppColors.paperBorder,
                        width: q == _amount ? 1.5 : 1,
                      ),
                      labelStyle: TextStyle(
                        fontWeight: q == _amount
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: q == _amount ? AppColors.statusOrange : AppColors.ink,
                      ),
                      onPressed: () => _selectAmount(q),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),

              // Campo numérico directo
              Text(
                'O escribe el valor exacto:',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                  hintText: '0',
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _amount = 0);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.paperBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.paperBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.paperBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.statusOrange, width: 1.5),
                  ),
                  errorText: isExceeded
                      ? 'No puedes descargar más de ${widget.maxAllowed.toCop}'
                      : null,
                ),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.statusOrange,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (val) {
                  setState(() {
                    _amount = int.tryParse(val) ?? 0;
                  });
                },
              ),
              const SizedBox(height: AppDimensions.space8),
              if (!isExceeded && isValid)
                Text(
                  'Quedarán en base por descargar: ${(widget.maxAllowed - _amount).toCop}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              const SizedBox(height: AppDimensions.space20),

              // Botón de confirmación
              SizedBox(
                height: AppDimensions.buttonHeightMd,
                child: FilledButton.icon(
                  onPressed: isValid
                      ? () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop(_amount);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.statusOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    isValid
                        ? 'Confirmar Descarga (${_amount.toCop})'
                        : 'Ingresa un monto válido',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settle Liquor Debt Bottom Sheet ───────────────────────────────────────────

class _LiquorSettlementResult {
  const _LiquorSettlementResult({
    required this.amount,
    this.note,
  });

  final int amount;
  final String? note;
}

class _SettleLiquorSheet extends StatefulWidget {
  const _SettleLiquorSheet({required this.summary});

  final WalletSummary summary;

  @override
  State<_SettleLiquorSheet> createState() => _SettleLiquorSheetState();
}

class _SettleLiquorSheetState extends State<_SettleLiquorSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  int _amount = 0;
  int? _selectedTxId;

  static final _timeFormat = DateFormat('hh:mm a', 'es_CO');

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();

    final liquorTxs = widget.summary.transactions
        .where((t) => t.type == TransactionType.liquorAdjustment)
        .toList();

    if (liquorTxs.length == 1) {
      final first = liquorTxs.first;
      _selectedTxId = first.id;
      final autoAmt = first.amount > widget.summary.totalLiquorDebt
          ? widget.summary.totalLiquorDebt
          : first.amount;
      _amount = autoAmt;
      _amountController.text = autoAmt.toString();
      _noteController.text = 'Pago en caja: ${first.note ?? "Botella"}';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _selectBottle(BaseTransactionEntity tx) {
    setState(() {
      _selectedTxId = tx.id;
      final targetAmount = tx.amount > widget.summary.totalLiquorDebt
          ? widget.summary.totalLiquorDebt
          : tx.amount;
      _amount = targetAmount;
      _amountController.text = targetAmount.toString();
      _noteController.text = 'Pago en caja: ${tx.note ?? "Botella"}';
    });
  }

  void _setAmount(int val) {
    setState(() {
      _selectedTxId = null;
      _amount = val;
      _amountController.text = val > 0 ? val.toString() : '';
      if (_noteController.text.isEmpty) {
        _noteController.text = 'Abono licor en caja';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxAllowed = widget.summary.totalLiquorDebt;
    final isValid = _amount > 0 && _amount <= maxAllowed;
    final isExceeded = _amount > maxAllowed;

    final liquorTxs = widget.summary.transactions
        .where((t) => t.type == TransactionType.liquorAdjustment)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.modalRadius),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.paperBorder, width: 1.0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space16,
        AppDimensions.pagePaddingH,
        AppDimensions.pagePaddingH + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.paperBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space8),
                    decoration: BoxDecoration(
                      color: AppColors.statusPurple.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wine_bar_rounded,
                      color: AppColors.statusPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pagar Botella en Caja',
                          style: AppTextStyles.titleLarge.copyWith(color: AppColors.ink),
                        ),
                        Text(
                          'Deuda de licor pendiente: ${maxAllowed.toCop}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),

              // Quick pay-all button chip
              Row(
                children: [
                  ActionChip(
                    avatar: const Icon(
                      Icons.flash_on_rounded,
                      size: 16,
                      color: AppColors.statusPurple,
                    ),
                    label: Text('Liquidar Todo (${maxAllowed.toCop})'),
                    backgroundColor: AppColors.paperBackground,
                    side: BorderSide(
                      color: AppColors.statusPurple.withValues(alpha: 0.4),
                    ),
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.statusPurple,
                      fontWeight: FontWeight.bold,
                    ),
                    onPressed: () => _setAmount(maxAllowed),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),

              // List of bottles charged (if any)
              if (liquorTxs.isNotEmpty) ...[
                Text(
                  'Selecciona una botella de la lista:',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: liquorTxs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final tx = liquorTxs[index];
                      final isSelected = _selectedTxId == tx.id;
                      final timeStr = _timeFormat.format(tx.timestamp);

                      return InkWell(
                        onTap: () => _selectBottle(tx),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space12,
                            vertical: AppDimensions.space10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.statusPurple.withValues(alpha: 0.12)
                                : AppColors.paperBackground,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.statusPurple
                                  : AppColors.paperBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected
                                    ? AppColors.statusPurple
                                    : AppColors.inkSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: AppDimensions.space10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.note ?? 'Botella de licor',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.ink,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      timeStr,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.inkSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                tx.amount.toCop,
                                style: AppTextStyles.receiptTotal.copyWith(
                                  fontSize: 16,
                                  color: AppColors.statusPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
              ],

              // Custom amount input
              Text(
                'Monto a pagar en caja (COP)',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.statusPurple,
                  ),
                  hintText: '0',
                  suffixIcon: _amountController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _amountController.clear();
                            setState(() {
                              _amount = 0;
                              _selectedTxId = null;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.paperBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.paperBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.paperBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.statusPurple, width: 1.5),
                  ),
                  errorText: isExceeded
                      ? 'No puedes liquidar más de ${maxAllowed.toCop}'
                      : null,
                ),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.statusPurple,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (val) {
                  setState(() {
                    _amount = int.tryParse(val) ?? 0;
                    _selectedTxId = null;
                  });
                },
              ),
              const SizedBox(height: AppDimensions.space12),

              // Note / concept
              TextField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Concepto / Detalle (opcional)',
                  labelStyle: TextStyle(color: AppColors.inkSecondary),
                  hintText: 'Ej. Pago Aguardiente en caja',
                  filled: true,
                  fillColor: AppColors.paperBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.paperBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.paperBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.statusPurple, width: 1.5),
                  ),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: AppDimensions.space12),

              // Summary calculation
              if (!isExceeded && isValid)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: AppColors.statusPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: AppColors.statusPurple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Deuda restante:',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                      ),
                      Text(
                        (maxAllowed - _amount).toCop,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.statusPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimensions.space20),

              // Confirmation button
              SizedBox(
                height: AppDimensions.buttonHeightMd,
                child: FilledButton.icon(
                  onPressed: isValid
                      ? () {
                          HapticFeedback.mediumImpact();
                          final noteText = _noteController.text.trim();
                          Navigator.of(context).pop(
                            _LiquorSettlementResult(
                              amount: _amount,
                              note: noteText.isEmpty
                                  ? 'Pago de licor en caja'
                                  : noteText,
                            ),
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.statusPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                    ),
                  ),
                  icon: const Icon(Icons.point_of_sale_rounded),
                  label: Text(
                    isValid
                        ? 'Registrar Pago en Caja (${_amount.toCop})'
                        : 'Ingresa un monto válido',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
            ],
          ),
        ),
      ),
    );
  }
}

