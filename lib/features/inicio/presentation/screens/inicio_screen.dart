import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/services/table_counter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/animated_amount.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../base_management/domain/entities/wallet_summary.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../tables/domain/entities/table_session_entity.dart';
import '../../../tables/presentation/widgets/new_table_dialog.dart';

/// Pantalla de inicio — optimizada para uso con una sola mano (Thumb Zone).
///
/// Prioriza accesos de gran tamaño para:
///   • "Nueva Mesa" (abre diálogo y navega de inmediato a tomar pedido).
///   • "El Radar" (pedidos en preparación con badge en tiempo real).
///   • "Cámara Rápida" (captura de comprobantes de transferencia sueltos).
///   • Estado de "Base vs. Deuda" (control financiero visible de un vistazo).
class InicioScreen extends ConsumerStatefulWidget {
  const InicioScreen({super.key});

  @override
  ConsumerState<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends ConsumerState<InicioScreen>
    with SingleTickerProviderStateMixin {
  // Persists for the app session — entrance animation plays once on first visit.
  static bool _hasEntrancePlayed = false;

  late AnimationController _ctrl;

  late Animation<double> _headerAnim;
  late Animation<double> _baseDeudaAnim;
  late Animation<double> _statsAnim;
  late Animation<double> _actionsAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _headerAnim    = _interval(0.00, 0.40);
    _baseDeudaAnim = _interval(0.12, 0.52);
    _statsAnim     = _interval(0.25, 0.65);
    _actionsAnim   = _interval(0.38, 0.78);

    if (_hasEntrancePlayed) {
      _ctrl.value = 1.0;
    } else {
      _ctrl.forward();
      _hasEntrancePlayed = true;
    }
  }

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _fadeSlide({
    required Animation<double> anim,
    required Widget child,
    Offset begin = const Offset(0, 0.22),
  }) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  Future<void> _openNewTable() async {
    final counter = TableCounterService();
    final previewNumber = await counter.peekNextTableNumber();
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (_) => NewTableDialog(
        tableNumber: previewNumber,
        onOpen: (apodo) async {
          final assignedNumber = await counter.nextTableNumber();
          final result = await ref
              .read(openTableUseCaseProvider)
              .call(tableNumber: assignedNumber, apodo: apodo);
          if (!mounted) return;
          if (result case Ok(:final value)) {
            // Navega de inmediato a la comanda de la mesa creada
            context.push('/tables/${value.id}/orders');
          } else if (result case Err(:final failure)) {
            AppToast.error(context, failure.message);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final walletAsync   = ref.watch(enrichedWalletSummaryProvider);
    final sessionsAsync = ref.watch(activeSessionsProvider);
    final radarCount    = ref.watch(pendingRadarCountProvider);

    final summary    = walletAsync.valueOrNull;
    final hasShift   = summary?.hasInitialBase ?? false;
    final openTables = sessionsAsync.valueOrNull
            ?.where((s) => s.status == TableStatus.open)
            .length ??
        0;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header con toggle día/noche ─────────────────────────────
          SliverToBoxAdapter(
            child: _fadeSlide(
              anim: _headerAnim,
              begin: const Offset(0, -0.15),
              child: _HeroHeader(isDark: isDark, hasShift: hasShift),
            ),
          ),

          // ── Estado Financiero: Base vs. Deuda ────────────────────────
          SliverToBoxAdapter(
            child: _fadeSlide(
              anim: _baseDeudaAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePaddingH,
                  0,
                  AppDimensions.pagePaddingH,
                  AppDimensions.space16,
                ),
                child: _BaseVsDeudaCard(
                  summary: summary,
                  hasShift: hasShift,
                  isDark: isDark,
                  onTap: () => context.go('/'),
                ),
              ),
            ),
          ),

          // ── Mini Stats Rápidas ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _fadeSlide(
              anim: _statsAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                ),
                child: _StatsRow(
                  openTables: openTables,
                  radarCount: radarCount,
                  balance: summary?.availableBalance ?? 0,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppDimensions.space20),
          ),

          // ── Acciones Ergonómicas (Thumb Zone) ────────────────────────
          SliverToBoxAdapter(
            child: _fadeSlide(
              anim: _actionsAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                ),
                child: _ThumbZoneActions(
                  isDark: isDark,
                  openTables: openTables,
                  radarCount: radarCount,
                  onNewTable: _openNewTable,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppDimensions.space64),
          ),
        ],
      ),
    );
  }
}

// ── Hero Header ────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.isDark, required this.hasShift});

  final bool isDark;
  final bool hasShift;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo',
    ];
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final dayLabel =
        '${weekdays[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}';

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
        MediaQuery.of(context).padding.top + AppDimensions.space16,
        AppDimensions.pagePaddingH,
        AppDimensions.space20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Billetera del Mesero',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  dayLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.paperSurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(color: AppColors.paperBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'THE BASE',
                  style: AppTextStyles.statusBadge.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.8,
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

// ── Estado Financiero: Base vs. Deuda ──────────────────────────────────────────

class _BaseVsDeudaCard extends StatelessWidget {
  const _BaseVsDeudaCard({
    required this.summary,
    required this.hasShift,
    required this.isDark,
    required this.onTap,
  });

  final WalletSummary? summary;
  final bool hasShift;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!hasShift || summary == null) {
      return Container(
        margin: const EdgeInsets.only(top: AppDimensions.space16),
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: AppColors.paperSurface,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          border: Border.all(
            color: AppColors.paperBorder,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.space10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turno no iniciado',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toca para registrar tu base inicial (\$300.000).',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    final balance = summary!.availableBalance;
    final isNegative = balance < 0;

    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.paperSurface,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(
          color: isNegative
              ? AppColors.statusRed.withValues(alpha: 0.5)
              : AppColors.paperBorder,
          width: isNegative ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior: Título y Pill de Turno Activo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CONTROL DE BILLETERA',
                          style: AppTextStyles.statusBadge.copyWith(
                            color: AppColors.inkSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.statusGreen.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Text(
                        'TURNO ACTIVO',
                        style: AppTextStyles.statusBadge.copyWith(
                          color: AppColors.statusGreen,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),

                // Dos columnas financieras: Base vs. Deuda
                Row(
                  children: [
                    // Columna 1: Base Comprometida
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BASE CAPITAL',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedAmount(
                            amount: summary!.baseCapital,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saldo: ${balance.toCop}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isNegative
                                  ? AppColors.statusRed
                                  : AppColors.statusGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 48,
                      width: 1,
                      color: AppColors.paperLine,
                    ),
                    const SizedBox(width: AppDimensions.space12),

                    // Columna 2: Deuda Total
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEUDA AL LOCAL',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedAmount(
                            amount: summary!.totalDebt,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.statusRed,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'A responder en cierre',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Alerta dinámica si el saldo es negativo
                if (isNegative) ...[
                  const SizedBox(height: AppDimensions.space12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.statusRed.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(
                        color: AppColors.statusRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.statusRed, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Saldo negativo. ¿Subiste base en caja? Toca para ver.',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.statusRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mini Stats Row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.openTables,
    required this.radarCount,
    required this.balance,
    required this.isDark,
  });

  final int openTables;
  final int radarCount;
  final int balance;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.table_restaurant_rounded,
            label: 'Mesas',
            value: '$openTables',
            accent: AppColors.primary,
            isDark: isDark,
            onTap: () => context.go('/tables'),
          ),
        ),
        const SizedBox(width: AppDimensions.space10),
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions_rounded,
            label: 'Pedidos',
            value: '$radarCount',
            accent:
                radarCount > 0 ? AppColors.statusOrange : AppColors.statusGreen,
            isDark: isDark,
            onTap: () => context.go('/radar'),
          ),
        ),
        const SizedBox(width: AppDimensions.space10),
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Saldo',
            value: balance == 0 ? '--' : balance.toCop,
            accent: balance >= 0 ? AppColors.statusGreen : AppColors.statusRed,
            isDark: isDark,
            onTap: () => context.go('/'),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paperSurface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space10,
            vertical: AppDimensions.space12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: AppColors.paperBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(height: AppDimensions.space6),
              Text(
                value,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Acciones Ergonómicas (Thumb Zone) ──────────────────────────────────────────

class _ThumbZoneActions extends ConsumerStatefulWidget {
  const _ThumbZoneActions({
    required this.isDark,
    required this.openTables,
    required this.radarCount,
    required this.onNewTable,
  });

  final bool isDark;
  final int openTables;
  final int radarCount;
  final VoidCallback onNewTable;

  @override
  ConsumerState<_ThumbZoneActions> createState() => _ThumbZoneActionsState();
}

class _ThumbZoneActionsState extends ConsumerState<_ThumbZoneActions> {
  bool _showMore = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final pendingTransfers = ref.watch(pendingTransfersProvider).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCIONES PRINCIPALES (PULGAR)',
          style: AppTextStyles.statusBadge.copyWith(
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.lightOnSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppDimensions.space12),

        // ── 1. BOTÓN AMPLIO: NUEVA MESA ───────────────────────────────
        _ThumbZoneHeroButton(
          title: 'NUEVA MESA',
          subtitle: 'Asignar mesa y abrir comanda al instante',
          icon: Icons.add_circle_rounded,
          gradient: const [AppColors.primary, AppColors.primaryDark],
          onTap: widget.onNewTable,
        ),
        const SizedBox(height: AppDimensions.space12),

        // ── 2. FILA DE BOTONES: EL RADAR + CÁMARA RÁPIDA ──────────────
        Row(
          children: [
            // EL RADAR
            Expanded(
              child: _ThumbZoneTile(
                title: 'EL RADAR',
                subtitle: 'Pedidos en cocina',
                icon: Icons.pending_actions_rounded,
                badgeText: widget.radarCount > 0 ? '${widget.radarCount}' : null,
                badgeColor: AppColors.statusOrange,
                gradient: const [
                  Color(0xFFE89020),
                  Color(0xFFBA6910),
                ],
                onTap: () => context.go('/radar'),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),

            // CÁMARA RÁPIDA
            Expanded(
              child: _ThumbZoneTile(
                title: 'CÁMARA',
                subtitle: 'Comprobante suelto',
                icon: Icons.camera_alt_rounded,
                badgeText: '⚡ Suelta',
                badgeColor: Colors.black26,
                gradient: const [
                  Color(0xFF0288D1),
                  Color(0xFF01579B),
                ],
                onTap: () => context.push('/transferencias/captura-suelta'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space16),

        // ── 3. GRID SECUNDARIO ────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.table_restaurant_rounded,
                title: 'Mesas',
                subtitle: '${widget.openTables} abiertas',
                gradient: const [AppColors.paperSurface, AppColors.paperSurface],
                onTap: () => context.go('/tables'),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: _ActionCard(
                icon: Icons.verified_rounded,
                title: pendingTransfers > 0
                    ? 'Legalizar ($pendingTransfers)'
                    : 'Legalizar',
                subtitle: 'Transferencias en caja',
                gradient: pendingTransfers > 0
                    ? const [Color(0xFFE65100), Color(0xFFBF360C)]
                    : const [AppColors.paperSurface, AppColors.paperSurface],
                textColor: pendingTransfers > 0 ? Colors.white : AppColors.ink,
                iconColor: pendingTransfers > 0 ? Colors.white : AppColors.primary,
                onTap: () => context.push('/legalizacion'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),

        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.restaurant_menu_rounded,
                title: 'Menú',
                subtitle: 'Productos y precios',
                gradient: const [AppColors.paperSurface, AppColors.paperSurface],
                onTap: () => context.push('/products'),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: _ActionCard(
                icon: Icons.lock_clock_rounded,
                title: 'Cierre',
                subtitle: 'Arqueo de turno',
                gradient: const [AppColors.paperSurface, AppColors.paperSurface],
                onTap: () => context.go('/cierre'),
              ),
            ),
          ],
        ),

        // ── 4. MÁS OPCIONES (PLEGABLE) ────────────────────────────────
        const SizedBox(height: AppDimensions.space12),
        InkWell(
          onTap: () => setState(() => _showMore = !_showMore),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  _showMore ? 'Menos opciones' : 'Más opciones',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _showMore ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              _showMore ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: AppDimensions.space8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.photo_library_rounded,
                        title: 'Comprobantes',
                        subtitle: 'Fotos guardadas',
                        gradient: const [
                          AppColors.paperSurface,
                          AppColors.paperSurface
                        ],
                        onTap: () => context.push('/comprobantes'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.history_rounded,
                        title: 'Historial',
                        subtitle: 'Turnos anteriores',
                        gradient: const [
                          AppColors.paperSurface,
                          AppColors.paperSurface
                        ],
                        onTap: () => context.push('/cierre/historial'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),
                _ActionCard(
                  icon: Icons.settings_rounded,
                  title: 'Configuración',
                  subtitle: 'Ajustes de la app',
                  gradient: const [
                    AppColors.paperSurface,
                    AppColors.paperSurface
                  ],
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Botón Héroe Amplio (Thumb Zone) ───────────────────────────────────────────

class _ThumbZoneHeroButton extends StatelessWidget {
  const _ThumbZoneHeroButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 68,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tile Mediano Amplio (Thumb Zone) ──────────────────────────────────────────

class _ThumbZoneTile extends StatelessWidget {
  const _ThumbZoneTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final String? badgeText;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor ?? Colors.white24,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusFull),
                              ),
                              child: Text(
                                badgeText!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta de Acción Estándar ─────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? AppColors.ink;
    final iconFg = iconColor ?? (textColor != null ? fg : AppColors.primary);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(color: AppColors.paperBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space12),
            child: Row(
              children: [
                Icon(icon, color: iconFg, size: 24),
                const SizedBox(width: AppDimensions.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: textColor != null
                              ? fg.withValues(alpha: 0.75)
                              : AppColors.inkSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
