import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/base_management/data/models/waiter_base_transaction.dart';
import '../../features/billing/data/models/payment_receipt.dart';
import '../../features/orders/data/models/order_item.dart';
import '../../features/products/data/models/product.dart';
import '../../features/shift_history/data/models/shift_snapshot.dart';
import '../../features/tables/data/models/table_session.dart';

/// Singleton wrapper around the single Isar database instance for The Base.
///
/// ── Initialization contract ──────────────────────────────────────────────────
/// Call [IsarService.initialize()] once in [main()] before [runApp].
/// After that, access the database via [IsarService.db] from anywhere.
///
/// ── Adding a new collection ───────────────────────────────────────────────────
/// 1. Create the model in `lib/features/{feature}/data/models/`.
/// 2. Run: `flutter pub run build_runner build --delete-conflicting-outputs`
/// 3. Import the generated `*Schema` constant below and add it to [_schemas].
///
/// ── Inspector ─────────────────────────────────────────────────────────────────
/// The Isar Inspector is enabled in debug builds only. Open:
///   https://inspect.isar.dev  →  connect to the running device.
final class IsarService {
  IsarService._();

  static Isar? _db;

  /// The single, initialized Isar instance.
  ///
  /// Throws an [AssertionError] in debug mode if accessed before [initialize].
  /// In release mode, access before initialization will throw a [StateError]
  /// from Isar itself — the assert is the early warning.
  static Isar get db {
    assert(
      _db != null && _db!.isOpen,
      'IsarService.initialize() must complete before accessing IsarService.db.\n'
      'Check that you await it in main() before runApp().',
    );
    return _db!;
  }

  static bool get isReady => _db != null && _db!.isOpen;

  // ── Schema registry ──────────────────────────────────────────────────────
  // ADD new CollectionSchema constants here as features are developed.
  // The order does not matter — Isar resolves cross-collection links internally.

  static final List<CollectionSchema<dynamic>> _schemas = [
    // ── base_management ──────────────────────────────────────────────
    WaiterBaseTransactionSchema,

    // ── tables ───────────────────────────────────────────────────────
    TableSessionSchema,

    // ── orders ───────────────────────────────────────────────────────
    OrderItemSchema,

    // ── billing ──────────────────────────────────────────────────────
    PaymentReceiptSchema,

    // ── products (added in Prompt 3) ─────────────────────────────────
    ProductSchema,

    // ── shift_history ─────────────────────────────────────────────────
    ShiftSnapshotSchema,
  ];

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Opens the Isar database with all registered schemas.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops if the
  /// database is already open.
  static Future<void> initialize() async {
    if (isReady) return;

    final dir = await getApplicationDocumentsDirectory();

    _db = await Isar.open(
      _schemas,
      directory: dir.path,
      name: 'thebase_db',
      inspector: kDebugMode,
    );

    debugPrint('[IsarService] Database opened at ${dir.path}/thebase_db.isar');
  }

  /// Closes the database connection.
  ///
  /// Only call this on app sign-out or in test tearDown.
  /// The OS will clean up on process termination — you do not need to call
  /// this on normal app lifecycle events (background, suspend).
  static Future<void> close() async {
    if (!isReady) return;
    await _db!.close();
    _db = null;
    debugPrint('[IsarService] Database closed.');
  }

  // ── Transactions ─────────────────────────────────────────────────────────

  /// Convenience wrapper for a write transaction.
  ///
  /// All writes to Isar MUST be wrapped in a transaction. Use this helper
  /// so callers don't reference [db] directly and risk a missing-transaction
  /// runtime error.
  ///
  /// ```dart
  /// await IsarService.write((isar) async {
  ///   isar.waiterBaseTransactions.put(transaction);
  /// });
  /// ```
  static Future<T> write<T>(Future<T> Function(Isar isar) action) {
    return db.writeTxn(() => action(db));
  }

  /// Convenience wrapper for a read transaction.
  ///
  /// Reads outside a transaction are auto-wrapped by Isar, but explicit
  /// read transactions improve performance for multi-step reads.
  static Future<T> read<T>(Future<T> Function(Isar isar) action) {
    return db.txn(() => action(db));
  }

  // ── Testing utilities ────────────────────────────────────────────────────

  /// Opens an in-memory Isar instance for unit/integration tests.
  ///
  /// Call in `setUp()` and pair with [close()] in `tearDown()`.
  /// Requires the `isar_flutter_libs` or `isar` package with native binaries.
  @visibleForTesting
  static Future<void> initializeForTest() async {
    if (isReady) return;

    // Tests run on the host machine — use a temp directory.
    final dir = await getTemporaryDirectory();

    _db = await Isar.open(
      _schemas,
      directory: dir.path,
      name: 'bonanza_test_${DateTime.now().millisecondsSinceEpoch}',
      inspector: false,
    );
  }

  /// Wipes all data in the current database.
  ///
  /// Only callable in debug/test builds. The [assert] becomes a no-op in
  /// release mode — use the [initializeForTest] guard instead.
  @visibleForTesting
  static Future<void> clearAll() async {
    assert(kDebugMode, 'clearAll() must not be called in release builds.');
    await write((isar) async => isar.clear());
    debugPrint('[IsarService] All collections cleared.');
  }
}
