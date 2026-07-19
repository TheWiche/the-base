import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/animated_amount.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/presentation/providers/order_providers.dart';
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
    setState(() => _isActionLoading = true);
    final failure =
        await ref.read(baseWalletProvider.notifier).initializeShift();
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (failure != null) {
      _showError(failure.message);
    } else {
      _showSuccess('Turno iniciado. Base: \$300.000');
    }
  }

  Future<void> _handleRequestIncrease() async {
    final confirmed = await _showIncreaseConfirmation();
    if (!confirmed || !mounted) return;

    setState(() => _isActionLoading = true);
    final failure =
        await ref.read(baseWalletProvider.notifier).requestIncrease();
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (failure != null) {
      _showError(failure.message);
    } else {
      _showSuccess('Incremento registrado: +\$100.000');
    }
  }

  Future<void> _handleRequestDecrease() async {
    final confirmed = await _showDecreaseConfirmation();
    if (!confirmed || !mounted) return;

    setState(() => _isActionLoading = true);
    final failure =
        await ref.read(baseWalletProvider.notifier).requestDecrease();
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (failure != null) {
      _showError(failure.message);
    } else {
      _showSuccess('Reducción registrada: −\$100.000');
    }
  }

  Future<bool> _showIncreaseConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _IncreaseConfirmationDialog(
            onConfirm: () => Navigator.of(ctx).pop(true),
            onCancel: () => Navigator.of(ctx).pop(false),
          ),
        ) ??
        false;
  }

  Future<bool> _showDecreaseConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _DecreaseConfirmationDialog(
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
                onRequestIncrease: _handleRequestIncrease,
                onRequestDecrease: _handleRequestDecrease,
              )
            : _NoShiftBody(
                isLoading: _isActionLoading,
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
    required this.onIniciarTurno,
  });

  final bool isLoading;
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
                color: AppColors.brand.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.brand,
                size: 64,
              ),
            ),
            const SizedBox(height: AppDimensions.space24),
            Text(
              'Sin turno activo',
              style: AppTextStyles.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Inicia tu turno para activar la billetera y comenzar a tomar pedidos.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // ── Iniciar turno CTA ─────────────────────────────────────
            IniciarTurnoButton(
              isLoading: isLoading,
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
    required this.onRequestIncrease,
    required this.onRequestDecrease,
  });

  final WalletSummary summary;
  final bool isActionLoading;
  final VoidCallback onRequestIncrease;
  final VoidCallback onRequestDecrease;

  @override
  State<_ActiveDashboard> createState() => _ActiveDashboardState();
}

class _ActiveDashboardState extends State<_ActiveDashboard>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _entranceCtrl;
  late final Animation<double> _metricsAnim;
  late final Animation<double> _actionsAnim;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    });

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
    _tabController.dispose();
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
          title: Text(
            AppStrings.appTagline,
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? AppColors.darkOnSurface : AppColors.darkOnBackground,
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: _WalletHeader(
              summary: widget.summary,
              balanceColor: balanceColor,
              isDark: isDark,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.brand,
            labelColor: AppColors.brand,
            unselectedLabelColor: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.lightOnSurfaceVariant,
            tabs: const [
              Tab(text: 'Resumen'),
              Tab(text: 'Movimientos'),
            ],
          ),
        ),

        // ── Tab content ────────────────────────────────────────────────
        if (_tabController.index == 0) ...[
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
                        onPressed: widget.onRequestIncrease,
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      _DecrementoButton(
                        isLoading: widget.isActionLoading,
                        isEnabled: widget.summary.canRequestDecrease,
                        onPressed: widget.onRequestDecrease,
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      const _PagarBotellaButton(),
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
    required this.isDark,
  });

  final WalletSummary summary;
  final Color balanceColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkBackground, AppColors.darkSurface]
              : [AppColors.brandDark, AppColors.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : Colors.white70,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AnimatedAmount(
                  amount: summary.availableBalance,
                  style: AppTextStyles.displayLarge.copyWith(
                    color: isDark ? balanceColor : Colors.white,
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
              color: isDark ? AppColors.darkOnSurfaceVariant : Colors.white70,
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.statusBadge.copyWith(color: color),
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
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkDisabled
                : AppColors.lightDisabled,
          ),
          const SizedBox(height: AppDimensions.space12),
          Text(
            'Sin movimientos aún',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkDisabled
                  : AppColors.lightDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pagar Botella button (#7) ──────────────────────────────────────────────────

class _PagarBotellaButton extends ConsumerWidget {
  const _PagarBotellaButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottles = ref.watch(unpaidLiquorItemsProvider).valueOrNull ?? [];
    final count = bottles.length;
    final has = count > 0;

    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightMd,
      child: OutlinedButton.icon(
        onPressed: has ? () => _showPicker(context, ref, bottles) : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: has
                ? AppColors.statusPurple
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
            width: has ? 2.0 : 1.5,
          ),
          backgroundColor:
              has ? AppColors.statusPurple.withOpacity(0.06) : Colors.transparent,
        ),
        icon: Badge(
          isLabelVisible: has,
          label: Text('$count'),
          backgroundColor: AppColors.statusPurple,
          child: Icon(Icons.wine_bar_rounded,
              color: has
                  ? AppColors.statusPurple
                  : (isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant)),
        ),
        label: Text(
          has ? 'Pagar Botella ($count)' : 'Sin botellas por pagar',
          style: AppTextStyles.labelLarge.copyWith(
            color: has
                ? AppColors.statusPurple
                : (isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant),
          ),
        ),
      ),
    );
  }

  void _showPicker(
    BuildContext context,
    WidgetRef ref,
    List<OrderItemEntity> bottles,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Completar botella',
                  style: AppTextStyles.headlineSmall),
            ),
            Text(
              'Baja la deuda de licor. No entra a tu saldo/efectivo.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.lightOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final b in bottles)
                    ListTile(
                      leading: const Icon(Icons.wine_bar_rounded,
                          color: AppColors.statusPurple),
                      title: Text(b.productName, style: AppTextStyles.bodyMedium),
                      subtitle: Text('Mesa ${b.tableSessionId} · ${b.lineTotal.toCop}',
                          style: AppTextStyles.bodySmall),
                      trailing: const Icon(Icons.check_circle_outline_rounded),
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        final failure =
                            await ref.read(settleLiquorActionProvider)(b.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(failure != null
                                ? failure.message
                                : 'Botella completada: ${b.productName}'),
                            backgroundColor: failure != null
                                ? AppColors.statusRed
                                : AppColors.statusGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
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
                  : AppColors.statusOrange.withOpacity(0.4),
              width: 1.5,
            ),
            foregroundColor: AppColors.statusOrange,
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
            'BAJAR BASE  −\$100.000',
            style: AppTextStyles.labelLarge.copyWith(
              color: canTap
                  ? AppColors.statusOrange
                  : AppColors.statusOrange.withOpacity(0.4),
              letterSpacing: 0.8,
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
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return AlertDialog(
      icon: const Icon(
        Icons.trending_up_rounded,
        color: AppColors.brand,
        size: AppDimensions.iconXl,
      ),
      title: Text(
        '¿Confirmar Incremento?',
        style: AppTextStyles.headlineSmall,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Se agregarán \$100.000 a tu base.\nEsta acción quedará registrada con la hora exacta.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.space16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12, vertical: AppDimensions.space10),
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.brand.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded, color: AppColors.brand, size: 16),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: AppTextStyles.mono.copyWith(color: AppColors.brand),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          SizedBox(
            height: AppDimensions.buttonHeightLg,
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: const Color(0xFF1A0A00),
              ),
              child: const Text(AppStrings.actionConfirm),
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          TextButton(
            onPressed: onCancel,
            child: const Text(AppStrings.actionCancel),
          ),
        ],
      ),
      actions: const [],
    );
  }
}

// ── Decrease confirmation dialog ───────────────────────────────────────────────

class _DecreaseConfirmationDialog extends StatelessWidget {
  const _DecreaseConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return AlertDialog(
      icon: const Icon(
        Icons.trending_down_rounded,
        color: AppColors.statusOrange,
        size: AppDimensions.iconXl,
      ),
      title: Text(
        '¿Bajar Base?',
        style: AppTextStyles.headlineSmall,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Se reducirán \$100.000 de tu base.\nEsta acción quedará registrada con la hora exacta.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.space16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12, vertical: AppDimensions.space10),
            decoration: BoxDecoration(
              color: AppColors.statusOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.statusOrange.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded,
                    color: AppColors.statusOrange, size: 16),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: AppTextStyles.mono.copyWith(color: AppColors.statusOrange),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          SizedBox(
            height: AppDimensions.buttonHeightLg,
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text(AppStrings.actionConfirm),
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          TextButton(
            onPressed: onCancel,
            child: const Text(AppStrings.actionCancel),
          ),
        ],
      ),
      actions: const [],
    );
  }
}
