import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_base/features/orders/domain/entities/order_item_entity.dart';
import 'package:the_base/features/orders/domain/entities/pending_radar_item.dart';
import 'package:the_base/features/orders/presentation/providers/order_providers.dart';
import 'package:the_base/features/radar/presentation/providers/radar_providers.dart';
import 'package:the_base/features/radar/presentation/screens/radar_screen.dart';

void main() {
  final now = DateTime.now();

  OrderItemEntity makeItem({
    required int id,
    required int sessionId,
    required String name,
    required int quantity,
    String? note,
    DateTime? orderedAt,
  }) {
    return OrderItemEntity(
      id: id,
      tableSessionId: sessionId,
      productName: name,
      price: 10000,
      quantity: quantity,
      category: ProductCategory.standard,
      orderedAt: orderedAt ?? now,
      status: OrderItemStatus.pending,
      isPaid: false,
      note: note,
    );
  }

  testWidgets('RadarScreen renders tripartite selector with 3 modes and displays Modo Barra by default',
      (tester) async {
    final pendingItems = [
      PendingRadarItem(
        item: makeItem(
          id: 1,
          sessionId: 10,
          name: 'Michelada Póker',
          quantity: 2,
        ),
        tableNumber: 1,
      ),
      PendingRadarItem(
        item: makeItem(
          id: 2,
          sessionId: 20,
          name: 'Michelada Póker',
          quantity: 2,
        ),
        tableNumber: 3,
        tableApodo: 'Terraza',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          radarClockProvider.overrideWith(
            (ref) => Stream.value(now),
          ),
          pendingRadarItemsProvider.overrideWith(
            (ref) => Stream.value(pendingItems),
          ),
          pendingRadarCountProvider.overrideWith(
            (ref) => 4,
          ),
        ],
        child: const MaterialApp(
          home: RadarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Selector tripartito visible
    expect(find.text('Cronológico'), findsOneWidget);
    expect(find.text('Por Mesas'), findsOneWidget);
    expect(find.text('Modo Barra'), findsOneWidget);

    // 2. Modo Barra activo por defecto mostrando el total consolidado [4x]
    expect(find.text('[4x]'), findsOneWidget);
    expect(find.text('Michelada Póker'), findsOneWidget);
    expect(find.textContaining('Mesa 1'), findsOneWidget);
    expect(find.textContaining('Mesa 3'), findsOneWidget);
    expect(find.text('Completar Todo (4)'), findsOneWidget);

    // 3. Cambiar a modo Por Mesas
    await tester.tap(find.text('Por Mesas'));
    await tester.pumpAndSettle();

    expect(find.text('MESA 1'), findsOneWidget);
    expect(find.text('MESA 3'), findsOneWidget);

    // 4. Cambiar a modo Cronológico
    await tester.tap(find.text('Cronológico'));
    await tester.pumpAndSettle();

    expect(find.text('2× Michelada Póker'), findsNWidgets(2));
  });

  testWidgets('Modo Barra triggers deliverItemsBatchProvider when tapping Completar Todo',
      (tester) async {
    final pendingItems = [
      PendingRadarItem(
        item: makeItem(
          id: 101,
          sessionId: 10,
          name: 'Gin Tonic',
          quantity: 1,
        ),
        tableNumber: 1,
      ),
      PendingRadarItem(
        item: makeItem(
          id: 102,
          sessionId: 20,
          name: 'Gin Tonic',
          quantity: 2,
        ),
        tableNumber: 2,
      ),
    ];

    List<int>? deliveredBatchIds;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          radarClockProvider.overrideWith(
            (ref) => Stream.value(now),
          ),
          pendingRadarItemsProvider.overrideWith(
            (ref) => Stream.value(pendingItems),
          ),
          pendingRadarCountProvider.overrideWith(
            (ref) => 3,
          ),
          deliverItemsBatchProvider.overrideWith(
            (ref) => (ids) async {
              deliveredBatchIds = ids;
              return null;
            },
          ),
        ],
        child: const MaterialApp(
          home: RadarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('[3x]'), findsOneWidget);
    expect(find.text('Completar Todo (3)'), findsOneWidget);

    // Tap Completar Todo
    await tester.tap(find.text('Completar Todo (3)'));
    await tester.pumpAndSettle();

    expect(deliveredBatchIds, equals([101, 102]));
  });

  testWidgets('Modo Barra triggers delivery for a specific table sub-batch chip',
      (tester) async {
    final pendingItems = [
      PendingRadarItem(
        item: makeItem(
          id: 201,
          sessionId: 10,
          name: 'Cuba Libre',
          quantity: 1,
        ),
        tableNumber: 5,
      ),
      PendingRadarItem(
        item: makeItem(
          id: 202,
          sessionId: 20,
          name: 'Cuba Libre',
          quantity: 3,
        ),
        tableNumber: 7,
      ),
    ];

    List<int>? deliveredSubBatchIds;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          radarClockProvider.overrideWith(
            (ref) => Stream.value(now),
          ),
          pendingRadarItemsProvider.overrideWith(
            (ref) => Stream.value(pendingItems),
          ),
          pendingRadarCountProvider.overrideWith(
            (ref) => 4,
          ),
          deliverItemsBatchProvider.overrideWith(
            (ref) => (ids) async {
              deliveredSubBatchIds = ids;
              return null;
            },
          ),
        ],
        child: const MaterialApp(
          home: RadarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Mesa 7 chip
    final mesa7Chip = find.textContaining('Mesa 7');
    expect(mesa7Chip, findsOneWidget);
    await tester.tap(mesa7Chip);
    await tester.pumpAndSettle();

    expect(deliveredSubBatchIds, equals([202]));
  });
}
