import '../../../orders/domain/entities/order_item_entity.dart';

/// A saved product in the waiter's local quick-access catalog.
///
/// Stored in SharedPreferences as JSON — no Isar collection needed for this
/// small, rarely-mutated list (typically 5–30 items per waiter).
final class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  /// Unique identifier — millisecond timestamp at creation time.
  final String id;
  final String name;

  /// Price in COP (integer).
  final int price;
  final ProductCategory category;

  bool get isLiquor => category == ProductCategory.liquor;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'category': category.name,
      };

  factory CatalogProduct.fromJson(Map<String, dynamic> json) => CatalogProduct(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toInt(),
        category: ProductCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ProductCategory.standard,
        ),
      );

  CatalogProduct copyWith({String? name, int? price, ProductCategory? category}) =>
      CatalogProduct(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        category: category ?? this.category,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CatalogProduct && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CatalogProduct($name, \$$price, ${category.name})';
}
