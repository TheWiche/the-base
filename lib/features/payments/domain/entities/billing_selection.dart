import '../../../orders/domain/entities/order_item_entity.dart';

/// Immutable state tracking which items — and how many units of each — the
/// waiter has selected for billing.
///
/// A line item can have quantity > 1 (e.g. "Cerveza ×3"). The customer may pay
/// for only some of those units, so selection is tracked as a per-item unit
/// count, not a simple boolean. [quantityOf] returns 0 for unselected items.
///
/// Only items that are `!isPaid && !isCancelled` should ever enter the map.
final class BillingSelection {
  const BillingSelection({this.quantities = const {}});

  /// itemId → number of units selected for this payment (1..lineQuantity).
  final Map<int, int> quantities;

  bool get isEmpty => quantities.isEmpty;

  /// Number of distinct lines with at least one unit selected.
  int get count => quantities.length;

  int quantityOf(int itemId) => quantities[itemId] ?? 0;
  bool isSelected(int itemId) => quantityOf(itemId) > 0;

  Set<int> get selectedItemIds => quantities.keys.toSet();

  /// itemId → units to pay, for the payment layer.
  Map<int, int> get selectedQuantities => Map.unmodifiable(quantities);

  /// Returns a new selection with [itemId] set to [qty] units.
  /// A qty of 0 or less removes the line from the selection.
  BillingSelection setQuantity(int itemId, int qty) {
    final next = Map<int, int>.from(quantities);
    if (qty <= 0) {
      next.remove(itemId);
    } else {
      next[itemId] = qty;
    }
    return BillingSelection(quantities: next);
  }

  /// Toggles a line fully in (at [maxQty] units) or fully out.
  BillingSelection toggle(int itemId, int maxQty) =>
      isSelected(itemId) ? setQuantity(itemId, 0) : setQuantity(itemId, maxQty);

  /// Selects every entry in [idToQty] at the given unit count.
  BillingSelection selectAll(Map<int, int> idToQty) =>
      BillingSelection(quantities: Map<int, int>.from(idToQty));

  /// Returns a new empty selection.
  BillingSelection clearAll() => const BillingSelection();

  /// Sum of `price × selected units` for every selected item.
  int subtotalOf(List<OrderItemEntity> items) => items.fold(0, (sum, i) {
        final q = quantityOf(i.id);
        return q > 0 ? sum + i.price * q : sum;
      });
}
