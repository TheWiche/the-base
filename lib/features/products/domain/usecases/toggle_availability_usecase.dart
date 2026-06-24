import '../../../../core/errors/result.dart';
import '../repositories/i_product_repository.dart';

final class ToggleAvailabilityUseCase {
  const ToggleAvailabilityUseCase(this._repository);

  final IProductRepository _repository;

  Future<Result<void>> call(int productId) =>
      _repository.toggleAvailability(productId);
}
