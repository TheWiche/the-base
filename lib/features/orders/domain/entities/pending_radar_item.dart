import 'order_item_entity.dart';

/// A [OrderItemEntity] enriched with its parent table context for El Radar.
///
/// Assembled by the repository via an in-memory join after fetching both
/// [OrderItem] and [TableSession] collections from Isar.
///
/// This is the canonical data type consumed by both radar view modes:
///   • Chronological: flat list sorted by [item.orderedAt] ASC.
///   • Grouped: keyed by [tableSessionId], sorted within group by orderedAt.
final class PendingRadarItem {
  const PendingRadarItem({
    required this.item,
    required this.tableNumber,
    this.tableApodo,
  });

  final OrderItemEntity item;
  final int tableNumber;

  /// The waiter's private nickname for the table.
  final String? tableApodo;

  int get tableSessionId => item.tableSessionId;

  /// Display label for the table header in grouped mode.
  /// Uses apodo when set: 'Mesa 5 — "Los cumpleañeros"'
  String get tableLabel {
    final base = 'Mesa $tableNumber';
    return tableApodo != null ? '$base — "$tableApodo"' : base;
  }

  /// Short form used in chronological mode item rows. Includes apodo when set.
  String get shortTableLabel {
    if (tableApodo != null) return 'Mesa $tableNumber · "$tableApodo"';
    return 'Mesa $tableNumber';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingRadarItem &&
          runtimeType == other.runtimeType &&
          item.id == other.item.id;

  @override
  int get hashCode => item.id.hashCode;
}

// ── Radar grouping helpers ─────────────────────────────────────────────────────

/// A table group used in the "Por Mesa" (grouped) radar view.
final class RadarTableGroup {
  const RadarTableGroup({
    required this.tableSessionId,
    required this.tableNumber,
    this.tableApodo,
    required this.items,
  });

  final int tableSessionId;
  final int tableNumber;
  final String? tableApodo;

  /// Items sorted oldest-first within the group.
  final List<PendingRadarItem> items;

  String get tableLabel {
    final base = 'Mesa $tableNumber';
    return tableApodo != null ? '$base — "$tableApodo"' : base;
  }

  int get pendingCount => items.length;

  /// The oldest item's timestamp — used to sort groups themselves
  /// so the most urgent table appears first.
  DateTime get oldestOrderedAt =>
      items.isEmpty ? DateTime.now() : items.first.item.orderedAt;
}

// ── Extension: group a flat PendingRadarItem list ─────────────────────────────

extension PendingRadarItemGrouping on List<PendingRadarItem> {
  /// Converts a flat list into [RadarTableGroup]s sorted by oldest-item-first.
  List<RadarTableGroup> toTableGroups() {
    final grouped = <int, List<PendingRadarItem>>{};
    for (final radar in this) {
      grouped.putIfAbsent(radar.tableSessionId, () => []).add(radar);
    }

    return grouped.entries.map((entry) {
      final items = entry.value
        ..sort((a, b) => a.item.orderedAt.compareTo(b.item.orderedAt));
      final first = items.first;
      return RadarTableGroup(
        tableSessionId: entry.key,
        tableNumber: first.tableNumber,
        tableApodo: first.tableApodo,
        items: items,
      );
    }).toList()
      ..sort((a, b) => a.oldestOrderedAt.compareTo(b.oldestOrderedAt));
  }
}
