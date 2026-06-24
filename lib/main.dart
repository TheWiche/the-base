import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/isar_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/services/table_counter_service.dart';
import 'features/tables/data/models/table_session.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/dashboard/presentation/providers/dashboard_providers.dart';
import 'features/orders/presentation/providers/order_providers.dart';
import 'features/products/data/repositories/product_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — waiter use case is always portrait.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // El estilo del sistema se actualiza dinámicamente en TheBaseApp.build()
  // según el modo oscuro/claro activo.

  // Initialize Spanish (Colombia) locale data BEFORE any widget builds.
  // Without this, every DateFormat(..., 'es_CO').format(...) throws
  // LocaleDataException, which in release mode renders the failing widget as a
  // gray ErrorWidget — expanding to infinite gray inside scrollable lists
  // (Movimientos, Legalizar Transferencias, Pedidos).
  await initializeDateFormatting('es_CO', null);

  await IsarService.initialize();
  await ProductRepositoryImpl().seedIfEmpty();
  await ProductRepositoryImpl().seedMigrateV2();
  await _migrateTableCounter();
  await NotificationService.initialize();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TheBaseApp(),
    ),
  );
}

/// Sets the table counter to the highest existing table number so the first
/// new table after an app update starts at max+1, never reusing a past number.
Future<void> _migrateTableCounter() async {
  final allSessions = await IsarService.db.tableSessions.where().anyId().findAll();
  if (allSessions.isEmpty) return;
  final maxNumber = allSessions.map((s) => s.tableNumber).reduce(
    (a, b) => a > b ? a : b,
  );
  await TableCounterService().ensureMinimum(maxNumber);
}

class TheBaseApp extends ConsumerWidget {
  const TheBaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    // Sincronizar barra de sistema Android con el modo activo.
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightBackground,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return _NotificationListenerWidget(
      child: MaterialApp.router(
        title: 'The Base',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        // Remove Android's stretch-overscroll effect. Its shader (saveLayer /
        // ImageFilter over the scrollable content) renders as a gray block on
        // Impeller + MIUI GPU drivers, making lists look broken/infinite.
        scrollBehavior: const _NoStretchScrollBehavior(),
        routerConfig: router,
      ),
    );
  }
}

/// App-wide scroll behavior that disables the overscroll indicator (the
/// Android 12+ stretch effect and the older glow). Both are skipped to avoid
/// the Impeller gray-block rendering bug on the target devices; scrolling still
/// clamps normally at the content edges.
class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

// ── Notification listener ──────────────────────────────────────────────────────

/// Watches pending order and transfer counts and fires local notifications
/// when thresholds are crossed or on the 15-minute periodic reminder.
class _NotificationListenerWidget extends ConsumerStatefulWidget {
  const _NotificationListenerWidget({required this.child});

  final Widget child;

  @override
  ConsumerState<_NotificationListenerWidget> createState() =>
      _NotificationListenerState();
}

class _NotificationListenerState
    extends ConsumerState<_NotificationListenerWidget> {
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    // Remind every 15 minutes if items are still pending.
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _periodicCheck(),
    );
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> _periodicCheck() async {
    final radarCount = ref.read(pendingRadarCountProvider);
    if (radarCount >= 3) {
      await NotificationService.showRadarAlert(radarCount);
    }
    final transferCount = ref.read(pendingTransfersProvider).length;
    if (transferCount > 0) {
      await NotificationService.showTransferAlert(transferCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Alert when pending orders cross the 5-item threshold.
    ref.listen<int>(pendingRadarCountProvider, (prev, next) {
      if (next >= 5 && (prev ?? 0) < 5) {
        NotificationService.showRadarAlert(next);
      }
    });

    // Alert when the first unlegalized transfer arrives.
    ref.listen(pendingTransfersProvider, (prev, next) {
      if (next.isNotEmpty && (prev?.isEmpty ?? true)) {
        NotificationService.showTransferAlert(next.length);
      }
    });

    return widget.child;
  }
}
