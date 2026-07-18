/// Pure domain entity for a menu product.
/// Never references Isar — callers work with this type, not the raw [Product] model.
final class ProductEntity {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.isLiquor,
    required this.isAvailable,
    this.subcategory,
  });

  final int id;
  final String name;

  /// Price in COP (integer — no decimals in Colombian hospitality).
  final int price;

  /// Human-readable category matching the Bonanza menu (e.g. "Granizados").
  final String category;

  /// Optional menu subcategory ("Cerveza", "Soda", …).
  final String? subcategory;

  /// Whether the product follows the liquor debt rule instead of reducing
  /// the waiter's active balance.
  final bool isLiquor;

  /// False when the waiter has marked this item as Agotado (out of stock).
  final bool isAvailable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProductEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
