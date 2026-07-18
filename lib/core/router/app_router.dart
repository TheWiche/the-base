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
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tables/presentation/screens/tables_screen.dart';
import '../theme/app_colors.dart';
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
        pageBuilder: (context, state) =>
            _slidePage(state.pageKey, const SettingsScreen()),
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
            _NavBar(
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

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar({
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
  Widget build(BuildContext context) {
    final bottomInset   = MediaQuery.of(context).viewPadding.bottom;
    final bg            = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final inactiveColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final dividerColor  = isDark ? AppColors.darkOutline : AppColors.lightOutline;

    return ColoredBox(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, thickness: 1, color: dividerColor),
          SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_shellDests.length, (i) {
                final dest     = _shellDests[i];
                final selected = i == currentIndex;
                final endColor = selected ? AppColors.primary : inactiveColor;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    // TweenAnimationBuilder anima el color de gris↔violeta
                    // sin ningún AnimationController ni StatefulWidget.
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: endColor),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      builder: (context, animColor, _) {
                        final c = animColor ?? endColor;

                        // Escala del ícono: 1.0 inactivo → 1.15 activo.
                        Widget icon = TweenAnimationBuilder<double>(
                          tween: Tween(end: selected ? 1.15 : 1.0),
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, _) => Transform.scale(
                            scale: scale,
                            // AnimatedSwitcher hace crossfade entre el ícono
                            // outlined (inactivo) y el filled (activo).
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              child: Icon(
                                selected
                                    ? (dest.activeIcon ?? dest.icon)
                                    : dest.icon,
                                key: ValueKey(selected),
                                size: 24,
                                color: c,
                              ),
                            ),
                          ),
                        );

                        if (i == 2 && radarCount > 0) {
                          icon = Badge(
                            label: Text('$radarCount'),
                            backgroundColor: AppColors.statusOrange,
                            child: icon,
                          );
                        }

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            icon,
                            const SizedBox(height: 4),
                            Text(
                              dest.label,
                              style: TextStyle(
                                color: c,
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}

