import '../entities/pending_radar_item.dart';
import '../repositories/i_order_repository.dart';

/// Exposes a reactive stream of all pending items for El Radar (KDS).
///
/// Each emission contains:
///   • All [OrderItemStatus.pending] items across ALL active tables.
///   • Items enriched with table number and apodo.
///   • Sorted chronologically (oldest orderedAt first).
///
/// The presentation layer derives both radar views from this single stream:
///   • Chronological mode  → use the list as-is.
///   • Grouped mode        → call [List<PendingRadarItem>.toTableGroups()].
///
/// The stream never completes — it lives as long as the Riverpod notifier
/// that owns it. New emissions are triggered by any Isar write to the
/// [OrderItem] or [TableSession] collections.
final class WatchPendingRadarItemsUseCase {
  const WatchPendingRadarItemsUseCase(this._repository);

  final IOrderRepository _repository;

  Stream<List<PendingRadarItem>> call() {
    return _repository.watchPendingRadarItems();
  }
}
