import 'package:flutter_test/flutter_test.dart';
import 'package:the_base/features/orders/domain/entities/order_item_entity.dart';
import 'package:the_base/features/orders/domain/entities/pending_radar_item.dart';
import 'package:the_base/features/radar/domain/entities/radar_bar_batch.dart';

void main() {
  group('PendingRadarItemBarGrouping.toBarBatches', () {
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
        price: 15000,
        quantity: quantity,
        category: ProductCategory.standard,
        orderedAt: orderedAt ?? now,
        status: OrderItemStatus.pending,
        isPaid: false,
        note: note,
      );
    }

    test('empty list returns empty batches', () {
      final items = <PendingRadarItem>[];
      final batches = items.toBarBatches();
      expect(batches, isEmpty);
    });

    test('groups identical products across different tables into one batch', () {
      final items = [
        PendingRadarItem(
          item: makeItem(
            id: 1,
            sessionId: 10,
            name: 'Michelada Póker',
            quantity: 1,
            orderedAt: now.subtract(const Duration(minutes: 8)),
          ),
          tableNumber: 1,
          tableApodo: 'Terraza',
        ),
        PendingRadarItem(
          item: makeItem(
            id: 2,
            sessionId: 20,
            name: 'Michelada Póker',
            quantity: 2,
            orderedAt: now.subtract(const Duration(minutes: 5)),
          ),
          tableNumber: 3,
        ),
        PendingRadarItem(
          item: makeItem(
            id: 3,
            sessionId: 30,
            name: 'Michelada Póker',
            quantity: 1,
            orderedAt: now.subtract(const Duration(minutes: 2)),
          ),
          tableNumber: 4,
          tableApodo: 'Toldo 4',
        ),
      ];

      final batches = items.toBarBatches();

      expect(batches.length, equals(1));
      final batch = batches.first;
      expect(batch.productName, equals('Michelada Póker'));
      expect(batch.totalQuantity, equals(4)); // 1 + 2 + 1 = 4
      expect(batch.allItemIds, equals([1, 2, 3]));
      expect(batch.tableDestinations.length, equals(3));

      // Verifies sub-batches breakdown
      expect(batch.tableDestinations[0].tableNumber, equals(1));
      expect(batch.tableDestinations[0].quantity, equals(1));
      expect(batch.tableDestinations[0].tableLabel, equals('Mesa 1 (Terraza)'));

      expect(batch.tableDestinations[1].tableNumber, equals(3));
      expect(batch.tableDestinations[1].quantity, equals(2));
      expect(batch.tableDestinations[1].tableLabel, equals('Mesa 3'));

      expect(batch.tableDestinations[2].tableNumber, equals(4));
      expect(batch.tableDestinations[2].quantity, equals(1));
      expect(batch.tableDestinations[2].tableLabel, equals('Mesa 4 (Toldo 4)'));
    });

    test('separates identical products with different notes', () {
      final items = [
        PendingRadarItem(
          item: makeItem(
            id: 1,
            sessionId: 10,
            name: 'Mojito Tradicional',
            quantity: 2,
            note: 'Sin alcohol',
          ),
          tableNumber: 1,
        ),
        PendingRadarItem(
          item: makeItem(
            id: 2,
            sessionId: 20,
            name: 'Mojito Tradicional',
            quantity: 1,
            note: 'Doble shot',
          ),
          tableNumber: 2,
        ),
        PendingRadarItem(
          item: makeItem(
            id: 3,
            sessionId: 30,
            name: 'Mojito Tradicional',
            quantity: 1,
            // Sin nota
          ),
          tableNumber: 3,
        ),
      ];

      final batches = items.toBarBatches();

      // Debe generar 3 lotes distintos porque las notas son diferentes
      expect(batches.length, equals(3));
      expect(batches.any((b) => b.note == 'Sin alcohol' && b.totalQuantity == 2), isTrue);
      expect(batches.any((b) => b.note == 'Doble shot' && b.totalQuantity == 1), isTrue);
      expect(batches.any((b) => b.note == null && b.totalQuantity == 1), isTrue);
    });

    test('sorts batches by oldest order first (urgency)', () {
      final items = [
        PendingRadarItem(
          item: makeItem(
            id: 1,
            sessionId: 10,
            name: 'Cerveza Corona',
            quantity: 1,
            orderedAt: now.subtract(const Duration(minutes: 1)),
          ),
          tableNumber: 1,
        ),
        PendingRadarItem(
          item: makeItem(
            id: 2,
            sessionId: 20,
            name: 'Gin Tonic',
            quantity: 1,
            orderedAt: now.subtract(const Duration(minutes: 12)),
          ),
          tableNumber: 2,
        ),
        PendingRadarItem(
          item: makeItem(
            id: 3,
            sessionId: 30,
            name: 'Cuba Libre',
            quantity: 1,
            orderedAt: now.subtract(const Duration(minutes: 6)),
          ),
          tableNumber: 3,
        ),
      ];

      final batches = items.toBarBatches();

      expect(batches.length, equals(3));
      expect(batches[0].productName, equals('Gin Tonic')); // más urgente (12m)
      expect(batches[0].urgency, equals(RadarUrgency.critical));
      expect(batches[1].productName, equals('Cuba Libre')); // 6m
      expect(batches[1].urgency, equals(RadarUrgency.warning));
      expect(batches[2].productName, equals('Cerveza Corona')); // 1m
      expect(batches[2].urgency, equals(RadarUrgency.normal));
    });
  });
}
