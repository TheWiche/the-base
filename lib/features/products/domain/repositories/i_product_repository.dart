import '../../../../core/errors/result.dart';
import '../entities/product_entity.dart';

abstract interface class IProductRepository {
  /// Seeds the menu with the 44 canonical products if the collection is empty.
  /// Safe to call on every app start — it is a no-op when data already exists.
  Future<void> seedIfEmpty();

  /// Reactive stream of all products, sorted by canonical category order then
  /// by name within each category.
  Stream<List<ProductEntity>> watchAll();

  /// Flips the [ProductEntity.isAvailable] flag for the given product.
  Future<Result<void>> toggleAvailability(int productId);

  /// Creates a new product. Returns the new id.
  Future<Result<int>> addProduct({
    required String name,
    required int price,
    required String category,
    String? subcategory,
    required bool isLiquor,
  });

  /// Updates an existing product's editable fields (name, price, category,
  /// subcategory, isLiquor). Availability is left untouched.
  Future<Result<void>> updateProduct({
    required int id,
    required String name,
    required int price,
    required String category,
    String? subcategory,
    required bool isLiquor,
  });

  /// Permanently deletes a product from the menu.
  Future<Result<void>> deleteProduct(int productId);
}
