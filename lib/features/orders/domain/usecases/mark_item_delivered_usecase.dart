import '../../../../core/errors/result.dart';
import '../entities/order_item_entity.dart';
import '../repositories/i_order_repository.dart';

/// Marks an order item as delivered and removes it from El Radar.
///
/// ── Business rules enforced ───────────────────────────────────────────────────
/// 1. Only [OrderItemStatus.pending] items can be marked delivered.
///    Attempting to deliver a cancelled or already-delivered item is a no-op.
/// 2. [deliveredAt] is set to [DateTime.now()] inside the repository at
///    write time — not passed from the caller — to prevent clock manipulation.
/// 3. After delivery, the item disappears from El Radar's active queue.
///    It remains visible in the table order screen (status = delivered).
///
/// ── El Radar effect ───────────────────────────────────────────────────────────
/// The [IOrderRepository.watchPendingRadarItems] stream automatically emits
/// a new list excluding this item as soon as Isar commits the write.
final class MarkItemDeliveredUseCase {
  const MarkItemDeliveredUseCase(this._repository);

  final IOrderRepository _repository;

  Future<Result<OrderItemEntity>> call(int itemId) async {
    return _repository.markDelivered(itemId);
  }
}
