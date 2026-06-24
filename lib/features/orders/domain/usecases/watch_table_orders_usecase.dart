import '../entities/order_item_entity.dart';
import '../repositories/i_order_repository.dart';

/// Reactive stream of all order items for a specific table session.
///
/// Returns items in ALL statuses (pending, delivered, cancelled) sorted
/// by [orderedAt] ASC — the table order screen shows the full history.
/// The Riverpod notifier filters by status for display grouping.
///
/// Used by [TableOrderScreen] to keep the item list live as new orders
/// are added or statuses change.
final class WatchTableOrdersUseCase {
  const WatchTableOrdersUseCase(this._repository);

  final IOrderRepository _repository;

  Stream<List<OrderItemEntity>> call(int sessionId) {
    return _repository.watchTableItems(sessionId);
  }
}
