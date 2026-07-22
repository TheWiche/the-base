import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../../../core/database/isar_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/base_transaction_entity.dart';
import '../../domain/repositories/i_base_repository.dart';
import '../models/waiter_base_transaction.dart';

/// Isar-backed implementation of [IBaseRepository].
///
/// ── Mapping convention ───────────────────────────────────────────────────────
/// [WaiterBaseTransaction] (Isar model) ↔ [BaseTransactionEntity] (domain).
/// The private extension [_WaiterBaseTransactionMapper] handles the conversion.
/// No domain object ever leaks into Isar writes — only primitives and Isar types.
///
/// ── Error handling ───────────────────────────────────────────────────────────
/// All Isar calls are wrapped in try/catch. [IsarError] and unexpected exceptions
/// are converted to [DatabaseFailure] so the domain layer never sees raw Dart
/// exceptions from the storage layer.
///
/// ── Reactive stream ──────────────────────────────────────────────────────────
/// [watchTransactions] uses Isar's native [watchLazy] stream. Every write to the
/// [WaiterBaseTransaction] collection emits a void event; we re-fetch the full
/// list on each event to guarantee consistency across concurrent writes.
final class BaseRepositoryImpl implements IBaseRepository {
  // Access the shared singleton. Never store the Isar instance as a field —
  // always read it via the service to respect the lifecycle contract.
  Isar get _db => IsarService.db;

  // ── Reactive reads ─────────────────────────────────────────────────────────

  @override
  Stream<List<BaseTransactionEntity>> watchTransactions() {
    // watchLazy fires a void event on every collection mutation.
    // We transform each event into a full re-fetch so the stream always
    // emits the complete, up-to-date list.
    return _db.waiterBaseTransactions
        .watchLazy(fireImmediately: true)
        .asyncMap((_) => _fetchAllSorted());
  }

  // ── One-shot reads ─────────────────────────────────────────────────────────

  @override
  Future<Result<List<BaseTransactionEntity>>> getAllTransactions() async {
    try {
      final entities = await _fetchAllSorted();
      return Ok(entities);
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<bool> hasInitialBase() async {
    final count = await _db.waiterBaseTransactions
        .filter()
        .typeEqualTo(TransactionType.initial)
        .count();
    return count > 0;
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  @override
  Future<Result<BaseTransactionEntity>> initializeShift({
    required int amount,
  }) async {
    try {
      final model = WaiterBaseTransaction()
        ..type = TransactionType.initial
        ..amount = amount
        ..timestamp = DateTime.now()
        ..note = 'Base inicial del turno';

      await IsarService.write((db) async {
        await db.waiterBaseTransactions.put(model);
      });

      debugPrint('[BaseRepo] Shift initialized: \$$amount at ${model.timestamp}');
      return Ok(model.toEntity());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<BaseTransactionEntity>> requestIncrease({
    required int amount,
  }) async {
    try {
      // Capture timestamp immediately — this is the auditable moment.
      final now = DateTime.now();

      final model = WaiterBaseTransaction()
        ..type = TransactionType.increase
        ..amount = amount
        ..timestamp = now;

      await IsarService.write((db) async {
        await db.waiterBaseTransactions.put(model);
      });

      debugPrint('[BaseRepo] Increase recorded: +\$$amount at $now');
      return Ok(model.toEntity());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<BaseTransactionEntity>> requestDecrease({
    required int amount,
  }) async {
    try {
      final now = DateTime.now();

      final model = WaiterBaseTransaction()
        ..type = TransactionType.decrease
        ..amount = amount
        ..timestamp = now;

      await IsarService.write((db) async {
        await db.waiterBaseTransactions.put(model);
      });

      debugPrint('[BaseRepo] Decrease recorded: −\$$amount at $now');
      return Ok(model.toEntity());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<BaseTransactionEntity>> recordLiquorAdjustment({
    required int amount,
    String? note,
  }) async {
    assert(amount > 0, 'Liquor adjustment amount must be positive.');
    try {
      final model = WaiterBaseTransaction()
        ..type = TransactionType.liquorAdjustment
        ..amount = amount
        ..timestamp = DateTime.now()
        ..note = note;

      await IsarService.write((db) async {
        await db.waiterBaseTransactions.put(model);
      });

      debugPrint('[BaseRepo] Liquor adjustment: +\$$amount debt');
      return Ok(model.toEntity());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    assert(kDebugMode, 'clearAll() is forbidden in release builds.');
    try {
      await IsarService.write(
        (db) async => db.waiterBaseTransactions.clear(),
      );
      return const Ok(null);
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<List<BaseTransactionEntity>> _fetchAllSorted() async {
    final models = await _db.waiterBaseTransactions
        .where()
        .sortByTimestamp()
        .findAll();
    return models.map((m) => m.toEntity()).toList();
  }
}

// ── Mapper extension ──────────────────────────────────────────────────────────

extension _WaiterBaseTransactionMapper on WaiterBaseTransaction {
  BaseTransactionEntity toEntity() => BaseTransactionEntity(
        id: id,
        type: type,
        amount: amount,
        timestamp: timestamp,
        note: note,
      );
}
