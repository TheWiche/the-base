import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:the_base/features/base_management/domain/entities/wallet_summary.dart';
import 'package:the_base/features/cierre/domain/entities/cierre_blocker.dart';
import 'package:the_base/features/cierre/presentation/providers/cierre_providers.dart';
import 'package:the_base/features/cierre/presentation/screens/cierre_screen.dart';
import 'package:the_base/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:the_base/features/orders/presentation/providers/order_providers.dart';
import 'package:the_base/features/tables/domain/entities/table_session_entity.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  const dummyWallet = WalletSummary(
    transactions: [],
    initialBase: 100000,
    totalIncreases: 0,
    totalDecreases: 0,
    totalLiquorDebt: 0,
    cashPaymentsTotal: 50000,
    verifiedTransfersTotal: 30000,
    transferTipsTotal: 5000,
  );

  testWidgets(
      'CierreScreen shows BLOQUEADO and disables Finalizar Jornada when blockers exist',
      (tester) async {
    final openSession = TableSessionEntity(
      id: 1,
      tableNumber: 3,
      openedAt: DateTime.now(),
      status: TableStatus.open,
    );

    final validationBlocked = CierreValidationResult(
      blockers: [
        OpenTablesBlocker(sessions: [openSession]),
        const PendingRadarBlocker(count: 2),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cierreValidationProvider.overrideWithValue(validationBlocked),
          enrichedWalletSummaryProvider
              .overrideWithValue(const AsyncData(dummyWallet)),
          closedSessionsProvider.overrideWith(
            (ref) async => [],
          ),
        ],
        child: const MaterialApp(
          home: CierreScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Badge y Banner de Bloqueo
    expect(find.text('BLOQUEADO'), findsOneWidget);
    expect(find.text('Cierre Bloqueado (Cierre Blindado)'), findsOneWidget);

    // 2. Mensajes de los blockers presentes
    expect(find.text('Mesas con Saldo Pendiente'), findsOneWidget);
    expect(find.text('Pedidos Pendientes en el Radar'), findsOneWidget);
    expect(find.textContaining('2 ítems pendientes sin entregar'), findsOneWidget);

    // 3. Botón de Finalizar Jornada deshabilitado
    final finalizarBtnFinder =
        find.widgetWithText(FilledButton, 'FINALIZAR JORNADA');
    expect(finalizarBtnFinder, findsOneWidget);
    final button = tester.widget<FilledButton>(finalizarBtnFinder);
    expect(button.onPressed, isNull);

    // 4. Verificación de diseño: NO existen campos para contar efectivo ni denominaciones
    expect(find.text('Efectivo en mano'), findsNothing);
    expect(find.text('Contar efectivo'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
      'CierreScreen shows LIBRE and direct Finalizar Jornada button when no blockers',
      (tester) async {
    const validationFree = CierreValidationResult(blockers: []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cierreValidationProvider.overrideWithValue(validationFree),
          enrichedWalletSummaryProvider
              .overrideWithValue(const AsyncData(dummyWallet)),
          closedSessionsProvider.overrideWith(
            (ref) async => [],
          ),
        ],
        child: const MaterialApp(
          home: CierreScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Badge de libre y header listo
    expect(find.text('LIBRE'), findsOneWidget);
    expect(find.text('Cierre Desbloqueado'), findsOneWidget);

    // 2. Resumen consolidado del turno visible
    expect(find.text('RESUMEN FINANCIERO DEL TURNO'), findsOneWidget);
    expect(find.text('Total Facturado'), findsOneWidget);
    expect(find.text('  · Ventas en efectivo'), findsOneWidget);
    expect(find.text('Deuda Total con Caja'), findsOneWidget);

    // 3. Botón de Finalizar Jornada habilitado directamente
    final finalizarBtnFinder =
        find.widgetWithText(FilledButton, 'FINALIZAR JORNADA');
    expect(finalizarBtnFinder, findsOneWidget);
    final button = tester.widget<FilledButton>(finalizarBtnFinder);
    expect(button.onPressed, isNotNull);

    // 4. Ningún formulario de conteo de efectivo
    expect(find.text('Efectivo en mano'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });
}
