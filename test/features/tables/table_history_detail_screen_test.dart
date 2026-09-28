import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:the_base/core/errors/failures.dart';
import 'package:the_base/core/settings/bar_settings_provider.dart';
import 'package:the_base/features/orders/domain/entities/order_item_entity.dart';
import 'package:the_base/features/orders/presentation/providers/order_providers.dart';
import 'package:the_base/features/payments/domain/entities/payment_receipt_entity.dart';
import 'package:the_base/features/payments/presentation/providers/payment_providers.dart';
import 'package:the_base/features/tables/domain/entities/table_session_entity.dart';
import 'package:the_base/features/tables/presentation/screens/table_history_detail_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  final now = DateTime(2026, 9, 28, 14, 30);

  testWidgets('TableHistoryDetailScreen renders read-only dual viewer with toggle',
      (tester) async {
    final session = TableSessionEntity(
      id: 1,
      tableNumber: 5,
      apodo: 'Cumpleaños',
      openedAt: now.subtract(const Duration(minutes: 90)),
      closedAt: now,
      status: TableStatus.closed,
      verificationCode: 'FAC-123456',
    );

    final items = [
      OrderItemEntity(
        id: 10,
        tableSessionId: 1,
        productName: 'Mojito Cubano',
        price: 18000,
        quantity: 2,
        category: ProductCategory.standard,
        orderedAt: now.subtract(const Duration(minutes: 80)),
        status: OrderItemStatus.delivered,
        isPaid: true,
        note: 'Hierbabuena extra',
      ),
    ];

    final payments = [
      PaymentReceiptEntity(
        id: 100,
        tableSessionId: 1,
        amountPaid: 36000,
        changeGiven: 0,
        tipAmount: 0,
        paymentMethod: PaymentMethod.transfer,
        transferMethod: TransferMethod.nequi,
        isLegalizedInCaja: true,
        verificationCode: 'TRF-987654',
        paidAt: now.subtract(const Duration(minutes: 5)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          barNameProvider.overrideWith(_FakeBarNameNotifier.new),
          sessionByIdProvider(1).overrideWith(
            (ref) async => session,
          ),
          tableOrderProvider.overrideWith(
            () => _FakeTableOrderNotifier(items),
          ),
          sessionPaymentsProvider(1).overrideWith(
            (ref) => Stream.value(payments),
          ),
        ],
        child: const MaterialApp(
          home: TableHistoryDetailScreen(sessionId: 1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Debe ser de solo lectura y tener el badge CERRADA
    expect(find.text('CERRADA'), findsOneWidget);
    // NO debe existir el botón gigante REACTIVAR en la pantalla
    expect(find.text('REACTIVAR'), findsNothing);

    // 2. Interruptor toggle superior presente
    expect(find.text('Modo Agrupado'), findsOneWidget);
    expect(find.text('Modo Cronológico'), findsOneWidget);

    // 3. En Modo Agrupado:
    expect(find.text('PRODUCTOS CONSUMIDOS'), findsOneWidget);
    expect(find.text('2× Mojito Cubano'), findsOneWidget);
    expect(find.text('↳ Hierbabuena extra'), findsOneWidget);
    expect(find.text('MÉTODOS DE PAGO UTILIZADOS'), findsOneWidget);
    expect(find.text('Transferencias:'), findsOneWidget);
    expect(find.textContaining('FACTURA: FAC-123456'), findsOneWidget);

    // 4. Alternar a Modo Cronológico:
    await tester.tap(find.text('Modo Cronológico'));
    await tester.pumpAndSettle();

    expect(find.text('LÍNEA DE TIEMPO (EVENTOS PASO A PASO)'), findsOneWidget);
    expect(find.text('Apertura de Mesa 5'), findsOneWidget);
    expect(find.text('2× Mojito Cubano'), findsOneWidget);
    expect(find.text('Pago'), findsOneWidget);
    expect(find.text('Cierre de Mesa y Liquidación'), findsOneWidget);
  });
}

class _FakeTableOrderNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<OrderItemEntity>, int>
    implements TableOrderNotifier {
  _FakeTableOrderNotifier(this._initialItems);
  final List<OrderItemEntity> _initialItems;

  @override
  int get sessionId => arg;

  @override
  Future<List<OrderItemEntity>> build(int arg) async => _initialItems;

  @override
  Future<Failure?> addItem(AddItemParams params) async => null;

  @override
  Future<Failure?> cancelItem(int itemId) async => null;

  @override
  Future<Failure?> clearCancelledItems() async => null;

  @override
  Future<Failure?> closeSession() async => null;

  @override
  Future<Failure?> deleteItem(int itemId) async => null;

  @override
  Future<Failure?> markDelivered(int itemId) async => null;

  @override
  Future<Failure?> renameApodo(String? newApodo) async => null;

  @override
  Future<Failure?> repeatItems(List<AddItemParams> items) async => null;

  @override
  Future<Failure?> settleLiquor(int itemId) async => null;

  @override
  Future<Failure?> uncancelItem(int itemId) async => null;
}

class _FakeBarNameNotifier extends BarNameNotifier {
  @override
  String build() => 'THE BASE BAR';
}
