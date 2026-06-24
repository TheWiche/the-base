import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/base_management/presentation/screens/base_wallet_screen.dart';
import '../../features/cierre/presentation/screens/cierre_screen.dart';
import '../../features/dashboard/presentation/screens/legalization_screen.dart';
import '../../features/inicio/presentation/screens/inicio_screen.dart';
import '../../features/orders/presentation/providers/order_providers.dart';
import '../../features/orders/presentation/screens/table_order_screen.dart';
import '../../features/shift_history/presentation/screens/shift_history_screen.dart';
import '../../features/tables/presentation/screens/table_history_detail_screen.dart';
import '../../features/tables/presentation/screens/table_history_screen.dart';
import '../../features/payments/presentation/providers/payment_providers.dart';
import '../../features/payments/presentation/screens/billing_screen.dart';
import '../../features/payments/presentation/screens/cash_payment_screen.dart';
import '../../features/payments/presentation/screens/standalone_transfer_screen.dart';
import '../../features/payments/presentation/screens/transfer_capture_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/radar/presentation/screens/radar_screen.dart';
import '../../features/tables/presentation/screens/tables_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_provider.dart';

// ── Route name constants ───────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const String inicio      = '/inicio';
  static const String dashboard   = '/';        // Billetera
  static const String radar       = '/radar';
  static const String tables      = '/tables';
  static const String tableDetail = '/tables/:tableId';
  static const String legalizacion = '/legalizacion';
  static const String tableOrders  = '/tables/:sessionId/orders';
  static const String products    = '/products';
  static const String billing     = '/billing/:sessionId';
  static const String cashPayment = '/billing/:sessionId/cash';
  static const String transferCapture = '/billing/:sessionId/transfer';
  static const String cierre      = '/cierre';
  static const String settings    = '/settings';
}

// ── Shell destinations — order defines tab position ───────────────────────────

class _ShellDest {
  const _ShellDest({
    required this.route,
    required this.label,
    required this.icon,
    this.activeIcon,
  });
  final String route;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
}

const _shellDests = <_ShellDest>[
  _ShellDest(
    route: AppRoutes.inicio,
    label: 'Inicio',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  _ShellDest(
    route: AppRoutes.tables,
    label: 'Mesas',
    icon: Icons.table_restaurant_outlined,
    activeIcon: Icons.table_restaurant_rounded,
  ),
  _ShellDest(
    route: AppRoutes.radar,
    label: 'Pedidos',
    icon: Icons.receipt_outlined,
    activeIcon: Icons.receipt_rounded,
  ),
  _ShellDest(
    route: AppRoutes.dashboard,
    label: 'Billetera',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet_rounded,
  ),
  _ShellDest(
    route: AppRoutes.cierre,
    label: 'Cierre',
    icon: Icons.lock_outline_rounded,
    activeIcon: Icons.lock_rounded,
  ),
];

// ── Custom page transition ─────────────────────────────────────────────────────

Page<T> _slidePage<T>(LocalKey key, Widget child) => CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondary, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        final fade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.5, curve: Curves.easeIn),
          ),
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

// ── GoRouter instance ──────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.inicio,
    debugLogDiagnostics: false,
    routes: [
      // ── Shell with animated bottom nav ──────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.inicio,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: InicioScreen()),
          ),
          GoRoute(
            path: AppRoutes.tables,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: TablesScreen()),
          ),
          GoRoute(
            path: AppRoutes.radar,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: RadarScreen()),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: BaseWalletScreen()),
          ),
          GoRoute(
            path: AppRoutes.cierre,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: CierreScreen()),
          ),
        ],
      ),

      // ── Full-screen routes (slide from bottom, no bottom nav) ──────────
      GoRoute(
        path: '/tables/historial',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const TableHistoryScreen()),
      ),

      GoRoute(
        path: '/tables/historial/:sessionId',
        pageBuilder: (context, state) {
          final raw = state.pathParameters['sessionId'] ?? '0';
          final sessionId = int.tryParse(raw) ?? 0;
          return _slidePage(
            state.pageKey,
            TableHistoryDetailScreen(sessionId: sessionId),
          );
        },
      ),

      GoRoute(
        path: '/tables/:sessionId/orders',
        pageBuilder: (context, state) {
          final raw = state.pathParameters['sessionId'] ?? '0';
          final sessionId = int.tryParse(raw) ?? 0;
          return _slidePage(
            state.pageKey,
            TableOrderScreen(sessionId: sessionId),
          );
        },
      ),

      GoRoute(
        path: '/billing/:sessionId',
        pageBuilder: (context, state) {
          final raw = state.pathParameters['sessionId'] ?? '0';
          final sessionId = int.tryParse(raw) ?? 0;
          return _slidePage(state.pageKey, BillingScreen(sessionId: sessionId));
        },
        routes: [
          GoRoute(
            path: 'cash',
            pageBuilder: (context, state) => _slidePage(
              state.pageKey,
              CashPaymentScreen(args: state.extra as PaymentNavigationArgs),
            ),
          ),
          GoRoute(
            path: 'transfer',
            pageBuilder: (context, state) => _slidePage(
              state.pageKey,
              TransferCaptureScreen(args: state.extra as PaymentNavigationArgs),
            ),
          ),
        ],
      ),

      GoRoute(
        path: '/transferencias/captura-suelta',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const StandaloneTransferScreen()),
      ),

      GoRoute(
        path: '/cierre/historial',
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const ShiftHistoryScreen()),
      ),

      GoRoute(
        path: AppRoutes.legalizacion,
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const LegalizationScreen()),
      ),

      GoRoute(
        path: AppRoutes.products,
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const ProductsScreen()),
      ),

      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _slidePage(
          state.pageKey,
          const _PlaceholderScreen(title: 'Configuración'),
        ),
      ),
    ],
  );
});

// ── Shell scaffold ─────────────────────────────────────────────────────────────

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location   = GoRouterState.of(context).uri.toString();
    final currentIdx = _indexFromLocation(location);
    final radarCount = ref.watch(pendingRadarCountProvider);

    // Derive isDark directly from Riverpod — bypasses any Theme.of(context)
    // inconsistency in the bottomNavigationBar slot on MIUI/Xiaomi devices.
    final themeMode  = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Column(
          children: [
            Expanded(child: child),
            _ChevereNavBar(
              currentIndex: currentIdx,
              radarCount: radarCount,
              isDark: isDark,
              onTap: (i) {
                HapticFeedback.selectionClick();
                context.go(_shellDests[i].route);
              },
            ),
          ],
        ),
      ),
    );
  }

  static int _indexFromLocation(String location) {
    for (var i = _shellDests.length - 1; i >= 0; i--) {
      final route = _shellDests[i].route;
      if (route == '/') {
        if (location == '/') return i;
      } else if (location.startsWith(route)) {
        return i;
      }
    }
    return 0;
  }
}

// ── Animated bottom navigation bar ────────────────────────────────────────────

class _ChevereNavBar extends StatefulWidget {
  const _ChevereNavBar({
    required this.currentIndex,
    required this.radarCount,
    required this.isDark,
    required this.onTap,
  });

  final int currentIndex;
  final int radarCount;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  State<_ChevereNavBar> createState() => _ChevereNavBarState();
}

class _ChevereNavBarState extends State<_ChevereNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pillCtrl;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _pillCtrl  = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(_ChevereNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _prevIndex = old.currentIndex;
      _pillCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _prevIndex = widget.currentIndex);
      });
    }
  }

  @override
  void dispose() {
    _pillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final n      = _shellDests.length;

    // La barra usa el mismo fondo que el Scaffold: se funde con el contenido
    // igual que TikTok. En oscuro zinc-950 ≈ negro — el scrim de MIUI es
    // invisible. En claro gray-50 ≈ blanco puro.
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final inactiveColor = isDark
        ? AppColors.darkOnSurfaceVariant  // zinc-400
        : AppColors.lightOnSurfaceVariant; // gray-500
    final dividerColor = isDark
        ? AppColors.darkOutline            // zinc-700
        : AppColors.lightOutline;          // gray-200

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return ColoredBox(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 64,
            child: Stack(
              children: [
                // Línea divisoria superior
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Divider(height: 1, thickness: 1, color: dividerColor),
                ),

                // Píldora deslizante
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tabW = constraints.maxWidth / n;
                    return AnimatedBuilder(
                      animation: _pillCtrl,
                      builder: (context, _) {
                        final t     = Curves.easeInOutCubic.transform(_pillCtrl.value);
                        final fromX = tabW * _prevIndex;
                        final toX   = tabW * widget.currentIndex;
                        final pillX = fromX + (toX - fromX) * t;

                        return Positioned(
                          left: pillX + 6,
                          top: 8,
                          width: tabW - 12,
                          height: 40,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(
                                alpha: isDark ? 0.15 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Fila de tabs
                Row(
                  children: List.generate(n, (i) {
                    final dest     = _shellDests[i];
                    final selected = i == widget.currentIndex;
                    final color    = selected ? AppColors.primary : inactiveColor;

                    Widget icon = Icon(
                      selected ? (dest.activeIcon ?? dest.icon) : dest.icon,
                      size: 22,
                      color: color,
                    );

                    if (i == 2 && widget.radarCount > 0) {
                      icon = Badge(
                        label: Text('${widget.radarCount}'),
                        backgroundColor: AppColors.statusOrange,
                        child: icon,
                      );
                    }

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onTap(i),
                        child: SizedBox(
                          height: 64,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: selected ? 1.12 : 1.0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutBack,
                                child: icon,
                              ),
                              const SizedBox(height: 3),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: color,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: selected ? 10.5 : 10,
                                ),
                                child: Text(dest.label),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          // Extiende el fondo hasta el borde físico de la pantalla.
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}

// ── Placeholder screen ─────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
