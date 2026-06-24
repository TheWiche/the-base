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
}
