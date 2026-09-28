import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/domain/entities/pending_radar_item.dart';

/// Destino por mesa de una parte del lote consolidado en Modo Barra.
final class RadarBarSubBatch {
  const RadarBarSubBatch({
    required this.tableSessionId,
    required this.tableNumber,
    this.tableApodo,
    required this.quantity,
    required this.itemIds,
    required this.oldestOrderedAt,
  });

  final int tableSessionId;
  final int tableNumber;
  final String? tableApodo;
  final int quantity;
  final List<int> itemIds;
  final DateTime oldestOrderedAt;

  String get tableLabel {
    final base = 'Mesa $tableNumber';
    return (tableApodo != null && tableApodo!.isNotEmpty) ? '$base ($tableApodo)' : base;
  }
}

/// Lote consolidado de productos idénticos para el "Modo Barra".
///
/// Agrupa todos los ítems pendientes de entregar de TODAS las mesas activas
/// que comparten el mismo producto y variante/nota.
final class RadarBarBatch {
  const RadarBarBatch({
    required this.productName,
    this.note,
    required this.totalQuantity,
    required this.tableDestinations,
    required this.oldestOrderedAt,
  });

  final String productName;
  final String? note;
  final int totalQuantity;
  final List<RadarBarSubBatch> tableDestinations;
  final DateTime oldestOrderedAt;

  /// Retorna todos los IDs de ítems que componen este lote consolidado.
  List<int> get allItemIds =>
      tableDestinations.expand((td) => td.itemIds).toList();

  /// Tiempo transcurrido desde el pedido más antiguo de este producto.
  Duration get elapsed => DateTime.now().difference(oldestOrderedAt);
  int get elapsedMinutes => elapsed.inMinutes;

  /// Urgencia basada en el ítem más antiguo del lote.
  RadarUrgency get urgency {
    final m = elapsedMinutes;
    if (m < 5) return RadarUrgency.normal;
    if (m < 10) return RadarUrgency.warning;
    return RadarUrgency.critical;
  }
}

/// Extensión para transformar la lista plana de `PendingRadarItem` en lotes consolidados de Modo Barra.
extension PendingRadarItemBarGrouping on List<PendingRadarItem> {
  List<RadarBarBatch> toBarBatches() {
    if (isEmpty) return const [];

    // Agrupación funcional por producto idéntico + nota
    final Map<String, ({String productName, String? note, List<PendingRadarItem> items})> productGroups = {};

    for (final radarItem in this) {
      final rawName = radarItem.item.productName.trim();
      final rawNote = radarItem.item.note?.trim();
      final hasNote = rawNote != null && rawNote.isNotEmpty;

      final key = '${rawName.toLowerCase()}|||${hasNote ? rawNote.toLowerCase() : ""}';

      if (!productGroups.containsKey(key)) {
        productGroups[key] = (
          productName: rawName,
          note: hasNote ? rawNote : null,
          items: <PendingRadarItem>[],
        );
      }
      productGroups[key]!.items.add(radarItem);
    }

    final batches = productGroups.values.map((group) {
      // Sub-agrupar por mesa dentro de este producto
      final Map<int, List<PendingRadarItem>> byTable = {};
      for (final pi in group.items) {
        byTable.putIfAbsent(pi.tableSessionId, () => []).add(pi);
      }

      final tableDestinations = byTable.entries.map((entry) {
        final tItems = entry.value;
        final first = tItems.first;
        final totalQty = tItems.fold<int>(0, (sum, i) => sum + i.item.quantity);
        final itemIds = tItems.map((i) => i.item.id).toList();
        final oldest = tItems
            .map((i) => i.item.orderedAt)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        return RadarBarSubBatch(
          tableSessionId: entry.key,
          tableNumber: first.tableNumber,
          tableApodo: first.tableApodo,
          quantity: totalQty,
          itemIds: itemIds,
          oldestOrderedAt: oldest,
        );
      }).toList()
        ..sort((a, b) => a.oldestOrderedAt.compareTo(b.oldestOrderedAt));

      final batchTotalQty =
          tableDestinations.fold<int>(0, (sum, td) => sum + td.quantity);
      final batchOldest = tableDestinations
          .map((td) => td.oldestOrderedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);

      return RadarBarBatch(
        productName: group.productName,
        note: group.note,
        totalQuantity: batchTotalQty,
        tableDestinations: tableDestinations,
        oldestOrderedAt: batchOldest,
      );
    }).toList();

    // Ordenar de más antiguo (urgente) a más reciente
    batches.sort((a, b) => a.oldestOrderedAt.compareTo(b.oldestOrderedAt));
    return batches;
  }
}
