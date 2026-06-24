import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/animated_amount.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../tables/domain/entities/table_session_entity.dart';

/// Pantalla de inicio — primer tab que ve el mesero al abrir la app.
///
/// Muestra el resumen del turno, stats rápidas, acciones principales,
/// y un toggle animado para cambiar entre modo oscuro / claro.
class InicioScreen extends ConsumerStatefulWidget {
  const InicioScreen({super.key});

  @override
  ConsumerState<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends ConsumerState<InicioScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  late Animation<double> _headerAnim;
  late Animation<double> _shiftBannerAnim;
  late Animation<double> _statsAnim;
  late Animation<double> _actionsAnim;
  late Animation<double> _guideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _headerAnim      = _interval(0.00, 0.40);
    _shiftBannerAnim = _interval(0.12, 0.52);
    _statsAnim       = _interval(0.25, 0.65);
    _actionsAnim     = _interval(0.38, 0.78);
    _guideAnim       = _interval(0.52, 1.00);

    _ctrl.forward();
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

  @override
  Widget build(BuildContext context) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final walletAsync   = ref.watch(enrichedWalletSummaryProvider);
    final sessionsAsync = ref.watch(activeSessionsProvider);
    final radarCount    = ref.watch(pendingRadarCountProvider);

    final hasShift   = walletAsync.valueOrNull?.hasInitialBase ?? false;
    final openTables = sessionsAsync.valueOrNull
            ?.where((s) => s.status == TableStatus.open)
            .length ??
        0;
    final balance = walletAsync.valueOrNull?.availableBalance ?? 0;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _fadeSlide(
              anim: _headerAnim,
              begin: const Offset(0, -0.15),
              child: _HeroHeader(isDark: isDark, hasShift: hasShift),
            ),
          ),

          SliverToBoxAdapter(
            child: _fadeSlide(
              anim: _shiftBannerAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePaddingH,
                  0,
                  AppDimensions.pagePaddingH,
                  AppDimensions.space16,
                ),
                child: _ShiftBanner(
                  hasShift: hasShift,
                  balance: balance,
                  isDark: isDark,
                ),
              ),
            ),
          ),

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
                  balance: balance,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppDimensions.space20),
          ),

          SliverToBoxAdapter(
            child: _fadeSlide(
              anim: _actionsAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                ),
                child: _QuickActions(isDark: isDark),
              ),
            ),
          ),

          if (!hasShift)
            SliverToBoxAdapter(
              child: _fadeSlide(
                anim: _guideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePaddingH,
                    AppDimensions.space24,
                    AppDimensions.pagePaddingH,
                    0,
                  ),
                  child: _NewUserGuide(isDark: isDark),
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
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkHeaderGradient
            : AppColors.lightHeaderGradient,
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        MediaQuery.of(context).padding.top + AppDimensions.space16,
        AppDimensions.pagePaddingH,
        AppDimensions.space24,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + fecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Billetera del Mesero',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  dayLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          // Toggle tema + pill turno
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const _ThemeToggle(),
              const SizedBox(height: AppDimensions.space8),
              // Shift indicator pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: hasShift
                      ? AppColors.statusGreen.withOpacity(0.18)
                      : Colors.white.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: hasShift
                        ? AppColors.statusGreen.withOpacity(0.55)
                        : Colors.white.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasShift
                            ? AppColors.statusGreen
                            : Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasShift ? 'Turno activo' : 'Sin turno',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: hasShift
                            ? AppColors.statusGreen
                            : Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Theme Toggle animado ───────────────────────────────────────────────────────

class _ThemeToggle extends ConsumerStatefulWidget {
  const _ThemeToggle();

  @override
  ConsumerState<_ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends ConsumerState<_ThemeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    // light mode → ctrl en 1.0; dark → 0.0
    final isDark = ref.read(themeModeProvider) != ThemeMode.light;
    _ctrl.value = isDark ? 0.0 : 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    final isDark = ref.read(themeModeProvider) != ThemeMode.light;
    if (isDark) {
      _ctrl.forward();
      ref.read(themeModeProvider.notifier).setMode(ThemeMode.light);
    } else {
      _ctrl.reverse();
      ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sincronizar si el modo cambia desde afuera
    ref.listen(themeModeProvider, (_, next) {
      final goLight = next == ThemeMode.light;
      if (goLight && _ctrl.value < 1) _ctrl.forward();
      if (!goLight && _ctrl.value > 0) _ctrl.reverse();
    });

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_ctrl.value);
          // t=0 → oscuro, t=1 → claro
          final circleLeft = 3.0 + t * 27.0;

          return Container(
            width: 58,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Color.lerp(
                const Color(0xFF3B1F6B), // oscuro: violeta profundo
                const Color(0xFFEDE9FE), // claro: violet-100
                t,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3 + t * 0.1),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: circleLeft,
                  top: 3,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(
                        AppColors.primaryLight,          // círculo oscuro: violeta claro
                        const Color(0xFFF59E0B),         // círculo claro: ámbar
                        t,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.lerp(
                            AppColors.primary,
                            const Color(0xFFF59E0B),
                            t,
                          )!
                              .withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      t < 0.5
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Shift Banner ───────────────────────────────────────────────────────────────

class _ShiftBanner extends StatelessWidget {
  const _ShiftBanner({
    required this.hasShift,
    required this.balance,
    required this.isDark,
  });

  final bool hasShift;
  final int balance;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (hasShift) {
      return Container(
        margin: const EdgeInsets.only(top: AppDimensions.space16),
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDark
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.lightOutline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SALDO DISPONIBLE',
                    style: AppTextStyles.statusBadge.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedAmount(
                    amount: balance,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: balance >= 0
                          ? AppColors.statusGreen
                          : AppColors.statusRed,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Sin turno — tarjeta de bienvenida
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.space16),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkSurface, AppColors.darkSurfaceVariant]
              : [AppColors.lightSurfaceVariant, AppColors.lightSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny_rounded,
            color: AppColors.secondary,
            size: 32,
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido!',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkOnBackground
                        : AppColors.lightOnSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Ve a Billetera para iniciar tu turno.',
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

// ── Stats Row ──────────────────────────────────────────────────────────────────

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
            icon: Icons.monetization_on_rounded,
            label: 'Saldo',
            value: balance == 0 ? '--' : balance.toCop,
            accent:
                balance >= 0 ? AppColors.statusGreen : AppColors.statusRed,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space12,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: accent.withOpacity(0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(height: AppDimensions.space6),
            Text(
              value,
              style: AppTextStyles.headlineSmall.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCIONES RÁPIDAS',
          style: AppTextStyles.statusBadge.copyWith(
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.lightOnSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppDimensions.space12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.table_restaurant_rounded,
                title: 'Mesas',
                subtitle: 'Abrir y gestionar',
                gradient: [AppColors.primary, AppColors.primaryDark],
                onTap: () => context.go('/tables'),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: _ActionCard(
                icon: Icons.receipt_long_rounded,
                title: 'Pedidos',
                subtitle: 'Ver en cocina',
                gradient: [AppColors.secondary, AppColors.secondaryDark],
                onTap: () => context.go('/radar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Billetera',
                subtitle: 'Saldo y turno',
                gradient: isDark
                    ? [AppColors.darkSurfaceVariant, AppColors.darkOutline]
                    : [AppColors.lightSurfaceVariant, AppColors.lightSurface],
                textColor: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.lightOnSurface,
                onTap: () => context.go('/'),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: _ActionCard(
                icon: Icons.lock_clock_rounded,
                title: 'Cierre',
                subtitle: 'Finalizar turno',
                gradient: isDark
                    ? [AppColors.darkSurfaceVariant, AppColors.darkOutline]
                    : [AppColors.lightSurfaceVariant, AppColors.lightSurface],
                textColor: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.lightOnSurface,
                onTap: () => context.go('/cierre'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),
        _ActionCard(
          icon: Icons.add_a_photo_rounded,
          title: 'Captura suelta',
          subtitle: 'Guardar comprobante sin mesa',
          gradient: const [Color(0xFF1976D2), Color(0xFF0D47A1)],
          onTap: () => context.push('/transferencias/captura-suelta'),
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.textColor = Colors.white,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  final Color textColor;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, color: widget.textColor, size: 28),
              const SizedBox(height: AppDimensions.space10),
              Text(
                widget.title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: widget.textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                widget.subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: widget.textColor.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── New-user guide ─────────────────────────────────────────────────────────────

class _NewUserGuide extends StatelessWidget {
  const _NewUserGuide({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CÓMO EMPEZAR',
          style: AppTextStyles.statusBadge.copyWith(
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.lightOnSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppDimensions.space12),
        _GuideStep(
          step: '1',
          icon: Icons.account_balance_wallet_rounded,
          title: 'Inicia tu turno',
          desc: 'Ve a Billetera y pulsa "Iniciar Turno" para activar tu base.',
          isDark: isDark,
        ),
        const SizedBox(height: AppDimensions.space8),
        _GuideStep(
          step: '2',
          icon: Icons.table_restaurant_rounded,
          title: 'Abre una mesa',
          desc: 'En Mesas, pulsa + para abrir una mesa y asígnale un apodo.',
          isDark: isDark,
        ),
        const SizedBox(height: AppDimensions.space8),
        _GuideStep(
          step: '3',
          icon: Icons.add_shopping_cart_rounded,
          title: 'Agrega pedidos',
          desc: 'Desde la mesa, añade productos. Aparecerán en Pedidos (cocina).',
          isDark: isDark,
        ),
        const SizedBox(height: AppDimensions.space8),
        _GuideStep(
          step: '4',
          icon: Icons.payments_rounded,
          title: 'Cobra y cierra',
          desc: 'Cuando el cliente pague, ve a Cobrar y registra el pago.',
          isDark: isDark,
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.step,
    required this.icon,
    required this.title,
    required this.desc,
    required this.isDark,
  });

  final String step;
  final IconData icon;
  final String title;
  final String desc;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.lightOutlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Center(
              child: Text(
                step,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppDimensions.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.lightOnSurface,
                  ),
                ),
                Text(
                  desc,
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
