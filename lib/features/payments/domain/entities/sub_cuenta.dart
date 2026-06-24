import '../../../orders/domain/entities/order_item_entity.dart';

/// Ephemeral grouping of order items under a single payer at a table.
///
/// SubCuenta objects are created and discarded within a single BillingScreen
/// session — they are never persisted to Isar. Once a cuenta is billed, the
/// underlying [OrderItemEntity.isPaid] flags are set by the normal payment flow.
final class SubCuenta {
  const SubCuenta({
    required this.id,
    required this.label,
    this.itemIds = const {},
  });

  final int id;
  final String label;

  /// IDs of the [OrderItemEntity] lines assigned to this cuenta.
  final Set<int> itemIds;

  bool contains(int itemId) => itemIds.contains(itemId);

  bool get isEmpty => itemIds.isEmpty;

  SubCuenta addItem(int itemId) =>
      SubCuenta(id: id, label: label, itemIds: {...itemIds, itemId});

  SubCuenta removeItem(int itemId) {
    final next = Set<int>.from(itemIds)..remove(itemId);
    return SubCuenta(id: id, label: label, itemIds: next);
  }

  SubCuenta rename(String newLabel) =>
      SubCuenta(id: id, label: newLabel, itemIds: itemIds);

  int subtotalOf(List<OrderItemEntity> items) => items
      .where((i) => itemIds.contains(i.id))
      .fold(0, (sum, i) => sum + i.lineTotal);
}

// ── Aggregate state ───────────────────────────────────────────────────────────

/// Immutable state for the sub-cuenta split mode.
final class SubCuentaState {
  const SubCuentaState({
    this.cuentas = const [],
    this.isActive = false,
  });

  final List<SubCuenta> cuentas;
  final bool isActive;

  Set<int> get assignedItemIds =>
      cuentas.fold(<int>{}, (s, c) => s..addAll(c.itemIds));

  /// Returns the cuenta that owns [itemId], or null if unassigned.
  SubCuenta? ownerOf(int itemId) {
    for (final c in cuentas) {
      if (c.contains(itemId)) return c;
    }
    return null;
  }
}
