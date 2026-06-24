import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/order_item_entity.dart';
import '../repositories/i_order_repository.dart';

/// Marks an order item as [OrderItemStatus.cancelled].
///
/// ── Business rules enforced ───────────────────────────────────────────────────
/// 1. Already-paid items cannot be cancelled (payment has settled them).
/// 2. Already-cancelled items are idempotent — no error, no write.
/// 3. The record is NEVER deleted. Cancelled items remain visible in the order
///    screen with a strikethrough to maintain a complete audit trail.
/// 4. If the item was [ProductCategory.liquor], the liquor debt adjustment that
///    was already written is NOT reversed. The bottle was ordered; the debt stands.
///    Reversals require a manual correction flow (out of scope for this prompt).
final class CancelOrderItemUseCase {
  const CancelOrderItemUseCase(this._repository);

  final IOrderRepository _repository;

  Future<Result<OrderItemEntity>> call(int itemId) async {
    // Delegate — the repository re-reads the item to verify preconditions.
    // The isPaid check is also enforced in the repository for data integrity.
    return _repository.cancelItem(itemId);
  }
}
