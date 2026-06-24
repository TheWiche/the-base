import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/order_item_entity.dart';
import '../repositories/i_order_repository.dart';

/// Adds a product to a table's order.
///
/// ── Liquor rule (CRITICAL) ────────────────────────────────────────────────────
/// When [AddItemParams.isLiquor] is true, the repository implementation MUST
/// atomically write:
///   1. The [OrderItem] record (for ordering and billing tracking).
///   2. A [WaiterBaseTransaction] of type [TransactionType.liquorAdjustment]
///      for the full [lineTotal] (for financial formula accuracy).
///
/// This use case enforces the invariant at the domain level by checking the
/// category and asserting the repository contract. The atomicity itself
/// is enforced inside [OrderRepositoryImpl] using a single Isar writeTxn.
///
/// Financial effect:
///   • Total Debt    += lineTotal   (via liquorAdjustment transaction)
///   • Available Bal  unchanged     (liquor does NOT deduct from base balance)
///
/// ── Custom items ──────────────────────────────────────────────────────────────
/// Items with [productCatalogId == null] are valid — they represent manually
/// typed items entered by the waiter for unlisted products.
final class AddOrderItemUseCase {
  const AddOrderItemUseCase(this._repository);

  final IOrderRepository _repository;

  Future<Result<OrderItemEntity>> call(AddItemParams params) async {
    // ── Input validation ────────────────────────────────────────────────────
    if (params.productName.trim().isEmpty) {
      return Err(
        const ValidationFailure(message: 'El nombre del producto no puede estar vacío.'),
      );
    }
    if (params.price <= 0) {
      return Err(
        const ValidationFailure(message: 'El precio debe ser mayor que \$0.'),
      );
    }
    if (params.quantity < 1) {
      return Err(
        const ValidationFailure(message: 'La cantidad debe ser al menos 1.'),
      );
    }

    // ── Delegate to repository (handles liquor atomicity internally) ─────────
    return _repository.addItem(params);
  }
}
