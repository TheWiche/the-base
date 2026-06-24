import '../../../../core/errors/result.dart';
import '../../../tables/domain/entities/table_session_entity.dart';
import '../entities/order_item_entity.dart';
import '../entities/pending_radar_item.dart';

/// Abstract contract for all order and table session data operations.
///
/// A single repository is used because [TableSession] and [OrderItem] are
/// tightly coupled: items cannot exist without a session, and session status
/// is driven by item payment state. Splitting them would require coordinating
/// two repositories for every write — an unnecessary complication at this scale.
///
/// ── Liquor rule ───────────────────────────────────────────────────────────────
/// The implementation is responsible for atomically writing BOTH the [OrderItem]
/// AND the [WaiterBaseTransaction] (liquorAdjustment) in a single Isar transaction
/// when [addItem] receives a liquor-category item. This guarantees the debt
/// record is never orphaned if the app crashes mid-write.
abstract interface class IOrderRepository {
  // ── Table session operations ───────────────────────────────────────────────

  /// Creates a new [TableSession] with status = open.
  /// Fails with [BusinessRuleFailure] if the table number is already open.
  Future<Result<TableSessionEntity>> openTable({
    required int tableNumber,
    String? apodo,
  });

  /// Returns all sessions with status open or partiallyPaid, sorted by
  /// [TableSessionEntity.tableNumber] ASC.
  Future<Result<List<TableSessionEntity>>> getActiveSessions();

  /// Reactive stream of active sessions. Rebuilds on every Isar write.
  Stream<List<TableSessionEntity>> watchActiveSessions();

  /// Returns a single session by its Isar ID.
  Future<Result<TableSessionEntity>> getSession(int sessionId);

  /// Updates the private nickname for the session.
  /// Pass null or empty string to clear the apodo.
  Future<Result<TableSessionEntity>> renameApodo(int sessionId, String? newApodo);

  /// Permanently deletes the session and all its cancelled items.
  /// Fails with [BusinessRuleFailure] if any non-cancelled items exist.
  Future<Result<void>> deleteSession(int sessionId);

  /// Returns all closed sessions sorted newest-first.
  Future<Result<List<TableSessionEntity>>> getClosedSessions();

  /// Reopens a closed session: status → open, clears closedAt and verificationCode.
  /// Existing items and payments are preserved.
  Future<Result<TableSessionEntity>> reactivateSession(int sessionId);

  // ── Order item operations ──────────────────────────────────────────────────

  /// Persists a new [OrderItem].
  ///
  /// If [AddItemParams.isLiquor] is true, also writes a
  /// [WaiterBaseTransaction.liquorAdjustment] in the SAME Isar transaction.
  Future<Result<OrderItemEntity>> addItem(AddItemParams params);

  /// Re-adds a batch of items to [sessionId] as new pending lines (e.g. the
  /// "repetir ronda" action). All items are written in a SINGLE Isar
  /// transaction, including any liquor adjustments. Re-ordering liquor adds new
  /// debt — it is a new bottle.
  Future<Result<void>> repeatItems(int sessionId, List<AddItemParams> items);

  /// Sets [OrderItemStatus.cancelled] on the item.
  /// Does NOT delete the record — cancelled items remain visible (strikethrough).
  /// Liquor adjustments already written are NOT reversed.
  Future<Result<OrderItemEntity>> cancelItem(int itemId);

  /// Permanently removes a single cancelled item from the database.
  /// Fails with [BusinessRuleFailure] if the item is not cancelled.
  Future<Result<void>> deleteItem(int itemId);

  /// Permanently removes ALL cancelled items for the given session.
  /// Liquor adjustments already written are NOT touched — only the UI record is removed.
  Future<Result<void>> clearCancelledItems(int sessionId);

  /// Sets [OrderItemStatus.delivered] and stamps [deliveredAt].
  Future<Result<OrderItemEntity>> markDelivered(int itemId);

  /// Reactive stream of all items for a specific table, sorted by orderedAt ASC.
  Stream<List<OrderItemEntity>> watchTableItems(int sessionId);

  // ── Radar operations ───────────────────────────────────────────────────────

  /// Reactive stream of ALL pending (non-cancelled, non-delivered) items across
  /// all active tables, enriched with table context for El Radar display.
  ///
  /// Sorted chronologically (oldest orderedAt first) — the chronological
  /// radar view uses this list directly. The grouped view calls
  /// [List<PendingRadarItem>.toTableGroups()] on the result.
  Stream<List<PendingRadarItem>> watchPendingRadarItems();

  /// One-shot fetch of pending radar items. Used by Cierre Blindado check.
  Future<Result<List<PendingRadarItem>>> getPendingRadarItems();
}
