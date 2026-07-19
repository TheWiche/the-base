import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../../../core/constants/financial_constants.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../base_management/data/models/waiter_base_transaction.dart';
import '../../../base_management/domain/entities/base_transaction_entity.dart';
import '../../../tables/data/models/table_session.dart';
import '../../../tables/domain/entities/table_session_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/entities/pending_radar_item.dart';
import '../../domain/repositories/i_order_repository.dart';
import '../models/order_item.dart';

/// Isar-backed implementation of [IOrderRepository].
///
/// ── Atomicity contract ────────────────────────────────────────────────────────
/// Every write that enforces the liquor business rule opens a SINGLE Isar
/// [writeTxn] covering BOTH the [OrderItem] put AND the [WaiterBaseTransaction]
/// put. If Isar aborts mid-transaction, neither record is committed — preventing
/// the ghost debt scenario where a debt record exists without a corresponding item.
///
/// ── Stream assembly for El Radar ─────────────────────────────────────────────
/// [watchPendingRadarItems] monitors [orderItems.watchLazy], re-fetches all
/// pending items on every change, and enriches them with table context via an
/// in-memory join. The join is fast because Isar is in-process (no network).
final class OrderRepositoryImpl implements IOrderRepository {
  Isar get _db => IsarService.db;

  // ── Table session operations ───────────────────────────────────────────────

  @override
  Future<Result<TableSessionEntity>> openTable({
    required int tableNumber,
    String? apodo,
  }) async {
    try {
      final model = TableSession()
        ..tableNumber = tableNumber
        ..apodo = apodo
        ..status = TableStatus.open
        ..openedAt = DateTime.now();

      await IsarService.write((db) async {
        await db.tableSessions.put(model);
      });

      debugPrint('[OrderRepo] Table $tableNumber opened (id: ${model.id})');
      return Ok(model.toEntity());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<List<TableSessionEntity>>> getActiveSessions() async {
    try {
      final models = await _db.tableSessions
          .filter()
          .statusEqualTo(TableStatus.open)
          .or()
          .statusEqualTo(TableStatus.partiallyPaid)
          .sortByTableNumber()
          .findAll();
      return Ok(models.map((m) => m.toEntity()).toList());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Stream<List<TableSessionEntity>> watchActiveSessions() {
    return _db.tableSessions
        .watchLazy(fireImmediately: true)
        .asyncMap((_) async {
      final models = await _db.tableSessions
          .filter()
          .statusEqualTo(TableStatus.open)
          .or()
          .statusEqualTo(TableStatus.partiallyPaid)
          .sortByTableNumber()
          .findAll();
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Result<TableSessionEntity>> getSession(int sessionId) async {
    try {
      final model = await _db.tableSessions.get(sessionId);
      if (model == null) {
        return Err(
          NotFoundFailure(message: 'Sesión de mesa #$sessionId no encontrada.'),
        );
      }
      return Ok(model.toEntity());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    }
  }

  @override
  Future<Result<TableSessionEntity>> renameApodo(
    int sessionId,
    String? newApodo,
  ) async {
    try {
      final model = await _db.tableSessions.get(sessionId);
      if (model == null) {
        return Err(
          NotFoundFailure(
            message: 'Sesión de mesa #$sessionId no encontrada.',
          ),
        );
      }
      final trimmed = newApodo?.trim();
      model.apodo = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
      await IsarService.write((db) async {
        await db.tableSessions.put(model);
      });
      debugPrint('[OrderRepo] Session $sessionId apodo → "${model.apodo}"');
      return Ok(model.toEntity());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  // ── Order item operations ──────────────────────────────────────────────────

  @override
  Future<Result<OrderItemEntity>> addItem(AddItemParams params) async {
    try {
      // Verify the session exists and is active before writing.
      final session = await _db.tableSessions.get(params.tableSessionId);
      if (session == null) {
        return Err(
          NotFoundFailure(
            message: 'Mesa no encontrada. Recarga y vuelve a intentarlo.',
          ),
        );
      }
      if (!session.status.isActive) {
        return Err(
          const BusinessRuleFailure(
            message: 'No se pueden agregar ítems a una mesa cerrada.',
          ),
        );
      }

      final now = DateTime.now();
      final orderModel = OrderItem()
        ..tableSessionId = params.tableSessionId
        ..productName = params.productName.trim()
        ..productCatalogId = params.productCatalogId
        ..price = params.price
        ..quantity = params.quantity
        ..category = params.category
        ..orderedAt = now
        ..status = OrderItemStatus.pending
        ..isPaid = false
        ..note = params.note?.trim().isEmpty ?? true ? null : params.note!.trim()
        ..menuCategory = params.menuCategory
        ..subcategory = params.subcategory;

      // ── Atomic write: item + optional liquor adjustment ─────────────────
      await IsarService.write((db) async {
        // 1. Persist the order item.
        await db.orderItems.put(orderModel);

        // 2. Link the item to the session (Isar IsarLinks).
        session.orderItems.add(orderModel);
        await session.orderItems.save();

        // 3. LIQUOR RULE: if this is a liquor item, write the debt record
        //    in the SAME transaction so both commits are atomic.
        if (params.isLiquor) {
          final adjustment = WaiterBaseTransaction()
            ..type = TransactionType.liquorAdjustment
            ..amount = params.lineTotal
            ..timestamp = now
            ..note = '${params.productName} ×${params.quantity}';
          await db.waiterBaseTransactions.put(adjustment);

          debugPrint(
            '[OrderRepo] Liquor rule applied: '
            '+\$${params.lineTotal} debt for "${params.productName}"',
          );
        }
      });

      debugPrint(
        '[OrderRepo] Item added: "${params.productName}" '
        '×${params.quantity} to session ${params.tableSessionId}',
      );
      return Ok(orderModel.toEntity());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> repeatItems(
    int sessionId,
    List<AddItemParams> items,
  ) async {
    if (items.isEmpty) return const Ok(null);
    try {
      final session = await _db.tableSessions.get(sessionId);
      if (session == null) {
        return Err(
          NotFoundFailure(
            message: 'Mesa no encontrada. Recarga y vuelve a intentarlo.',
          ),
        );
      }
      if (!session.status.isActive) {
        return Err(
          const BusinessRuleFailure(
            message: 'No se pueden agregar ítems a una mesa cerrada.',
          ),
        );
      }

      final now = DateTime.now();

      await IsarService.write((db) async {
        for (final params in items) {
          final note = params.note?.trim();
          final orderModel = OrderItem()
            ..tableSessionId = sessionId
            ..productName = params.productName.trim()
            ..productCatalogId = params.productCatalogId
            ..price = params.price
            ..quantity = params.quantity
            ..category = params.category
            ..orderedAt = now
            ..status = OrderItemStatus.pending
            ..isPaid = false
            ..note = (note == null || note.isEmpty) ? null : note
            ..menuCategory = params.menuCategory
            ..subcategory = params.subcategory;

          await db.orderItems.put(orderModel);
          session.orderItems.add(orderModel);

          // LIQUOR RULE: each re-ordered liquor line books new debt atomically.
          if (params.isLiquor) {
            final adjustment = WaiterBaseTransaction()
              ..type = TransactionType.liquorAdjustment
              ..amount = params.lineTotal
              ..timestamp = now
              ..note = '${params.productName} ×${params.quantity}';
            await db.waiterBaseTransactions.put(adjustment);
          }
        }
        await session.orderItems.save();
      });

      debugPrint(
        '[OrderRepo] Repeated ${items.length} item(s) into session $sessionId',
      );
      return const Ok(null);
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<OrderItemEntity>> cancelItem(int itemId) async {
    try {
      final model = await _db.orderItems.get(itemId);
      if (model == null) {
        return Err(NotFoundFailure(message: 'Ítem #$itemId no encontrado.'));
      }

      // Idempotent: already cancelled → return current state, no write.
      if (model.status == OrderItemStatus.cancelled) {
        return Ok(model.toEntity());
      }

      // Guard: paid items cannot be cancelled.
      if (model.isPaid) {
        return Err(
          const BusinessRuleFailure(
            message: 'Este ítem ya fue pagado y no puede cancelarse.',
          ),
        );
      }

      model.status = OrderItemStatus.cancelled;

      await IsarService.write((db) async {
        await db.orderItems.put(model);
      });

      debugPrint('[OrderRepo] Item #$itemId cancelled.');
      return Ok(model.toEntity());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> settleLiquorItem(int itemId) async {
    try {
      final model = await _db.orderItems.get(itemId);
      if (model == null) {
        return Err(NotFoundFailure(message: 'Ítem #$itemId no encontrado.'));
      }
      if (model.category != ProductCategory.liquor) {
        return Err(const BusinessRuleFailure(
          message: 'Solo las botellas de licor se pueden completar.',
        ));
      }
      if (model.isPaid) {
        return Ok(null);
      }

      final now = DateTime.now();
      final lineTotal = model.price * model.quantity;

      await IsarService.write((db) async {
        // 1. Marca la botella como pagada/entregada (sale de la cuenta y del radar).
        model
          ..isPaid = true
          ..status = OrderItemStatus.delivered
          ..deliveredAt = model.deliveredAt ?? now;
        await db.orderItems.put(model);

        // 2. Contrapartida de deuda: reduce la deuda de licor (pass-through).
        //    NO se crea PaymentReceipt → no infla saldo/efectivo del mesero.
        final settlement = WaiterBaseTransaction()
          ..type = TransactionType.liquorSettlement
          ..amount = lineTotal
          ..timestamp = now
          ..note = '${model.productName} ×${model.quantity}';
        await db.waiterBaseTransactions.put(settlement);
      });

      debugPrint('[OrderRepo] Liquor item #$itemId settled: -\$$lineTotal debt.');
      return const Ok(null);
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<List<TableSessionEntity>>> getClosedSessions() async {
    try {
      final models = await _db.tableSessions
          .filter()
          .statusEqualTo(TableStatus.closed)
          .findAll();
      models.sort(
        (a, b) =>
            (b.closedAt ?? b.openedAt).compareTo(a.closedAt ?? a.openedAt),
      );
      return Ok(models.map((m) => m.toEntity()).toList());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<TableSessionEntity>> reactivateSession(int sessionId) async {
    try {
      final model = await _db.tableSessions.get(sessionId);
      if (model == null) {
        return Err(
          NotFoundFailure(
            message: 'Sesión de mesa #$sessionId no encontrada.',
          ),
        );
      }
      if (model.status != TableStatus.closed) {
        return Err(
          const BusinessRuleFailure(
            message: 'Solo se pueden reactivar mesas cerradas.',
          ),
        );
      }
      model
        ..status = TableStatus.open
        ..closedAt = null
        ..verificationCode = null;
      await IsarService.write((db) async {
        await db.tableSessions.put(model);
      });
      debugPrint('[OrderRepo] Session $sessionId reactivated.');
      return Ok(model.toEntity());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> deleteSession(int sessionId) async {
    try {
      final session = await _db.tableSessions.get(sessionId);
      if (session == null) return const Ok(null); // idempotent

      // Guard: any non-cancelled item blocks deletion.
      final activeItems = await _db.orderItems
          .filter()
          .tableSessionIdEqualTo(sessionId)
          .not()
          .statusEqualTo(OrderItemStatus.cancelled)
          .findAll();

      if (activeItems.isNotEmpty) {
        return Err(
          const BusinessRuleFailure(
            message:
                'No se puede eliminar una mesa con ítems pendientes o pagados.',
          ),
        );
      }

      // Collect all item IDs (cancelled only at this point).
      final allItemIds = await _db.orderItems
          .filter()
          .tableSessionIdEqualTo(sessionId)
          .idProperty()
          .findAll();

      await IsarService.write((db) async {
        if (allItemIds.isNotEmpty) {
          await db.orderItems.deleteAll(allItemIds);
        }
        await db.tableSessions.delete(sessionId);
      });

      debugPrint('[OrderRepo] Session $sessionId deleted.');
      return const Ok(null);
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> deleteItem(int itemId) async {
    try {
      final model = await _db.orderItems.get(itemId);
      if (model == null) return const Ok(null); // idempotent

      if (model.status != OrderItemStatus.cancelled) {
        return Err(
          const BusinessRuleFailure(
            message: 'Solo se pueden eliminar ítems cancelados.',
          ),
        );
      }

      await IsarService.write((db) async {
        await db.orderItems.delete(itemId);
      });

      debugPrint('[OrderRepo] Cancelled item #$itemId deleted.');
      return const Ok(null);
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> clearCancelledItems(int sessionId) async {
    try {
      final models = await _db.orderItems
          .filter()
          .tableSessionIdEqualTo(sessionId)
          .statusEqualTo(OrderItemStatus.cancelled)
          .findAll();

      if (models.isEmpty) return const Ok(null);

      final ids = models.map((m) => m.id).toList();
      await IsarService.write((db) async {
        await db.orderItems.deleteAll(ids);
      });

      debugPrint(
        '[OrderRepo] Cleared ${ids.length} cancelled item(s) from session $sessionId.',
      );
      return const Ok(null);
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<OrderItemEntity>> markDelivered(int itemId) async {
    try {
      final model = await _db.orderItems.get(itemId);
      if (model == null) {
        return Err(NotFoundFailure(message: 'Ítem #$itemId no encontrado.'));
      }

      // Idempotent: already delivered → return, no write.
      if (model.status == OrderItemStatus.delivered) {
        return Ok(model.toEntity());
      }

      // Only pending items can be delivered.
      if (model.status == OrderItemStatus.cancelled) {
        return Err(
          const BusinessRuleFailure(
            message: 'Un ítem cancelado no puede marcarse como entregado.',
          ),
        );
      }

      model
        ..status = OrderItemStatus.delivered
        ..deliveredAt = DateTime.now();

      await IsarService.write((db) async {
        await db.orderItems.put(model);
      });

      debugPrint('[OrderRepo] Item #$itemId marked delivered.');
      return Ok(model.toEntity());
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Future<Result<void>> markTableDelivered(int sessionId) async {
    try {
      final pending = await _db.orderItems
          .filter()
          .tableSessionIdEqualTo(sessionId)
          .statusEqualTo(OrderItemStatus.pending)
          .findAll();
      if (pending.isEmpty) return const Ok(null);

      final now = DateTime.now();
      for (final m in pending) {
        m
          ..status = OrderItemStatus.delivered
          ..deliveredAt = now;
      }
      await IsarService.write((db) async {
        await db.orderItems.putAll(pending);
      });
      debugPrint('[OrderRepo] ${pending.length} items of table $sessionId delivered.');
      return const Ok(null);
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  @override
  Stream<List<OrderItemEntity>> watchTableItems(int sessionId) {
    return _db.orderItems
        .watchLazy(fireImmediately: true)
        .asyncMap((_) async {
      final models = await _db.orderItems
          .filter()
          .tableSessionIdEqualTo(sessionId)
          .sortByOrderedAt()
          .findAll();
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Stream<List<OrderItemEntity>> watchUnpaidLiquorItems() {
    return _db.orderItems
        .watchLazy(fireImmediately: true)
        .asyncMap((_) async {
      final models = await _db.orderItems
          .filter()
          .categoryEqualTo(ProductCategory.liquor)
          .isPaidEqualTo(false)
          .not()
          .statusEqualTo(OrderItemStatus.cancelled)
          .sortByOrderedAt()
          .findAll();
      return models.map((m) => m.toEntity()).toList();
    });
  }

  // ── Radar operations ───────────────────────────────────────────────────────

  @override
  Stream<List<PendingRadarItem>> watchPendingRadarItems() {
    return _db.orderItems
        .watchLazy(fireImmediately: true)
        .asyncMap((_) => _assemblePendingRadarItems());
  }

  @override
  Future<Result<List<PendingRadarItem>>> getPendingRadarItems() async {
    try {
      final items = await _assemblePendingRadarItems();
      return Ok(items);
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(DatabaseFailure(message: e.toString(), stackTrace: st));
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<List<PendingRadarItem>> _assemblePendingRadarItems() async {
    // 1. Fetch all pending items across all tables.
    final pendingModels = await _db.orderItems
        .filter()
        .statusEqualTo(OrderItemStatus.pending)
        .sortByOrderedAt()
        .findAll();

    if (pendingModels.isEmpty) return [];

    // 2. Collect the unique session IDs referenced by those items.
    final sessionIds =
        pendingModels.map((m) => m.tableSessionId).toSet().toList();

    // 3. Batch-fetch all relevant sessions in one Isar call (no N+1).
    final sessionModels = await _db.tableSessions.getAll(sessionIds);

    // 4. Build a lookup map: sessionId → TableSession model.
    final sessionMap = <int, TableSession>{};
    for (final s in sessionModels) {
      if (s != null) sessionMap[s.id] = s;
    }

    // 5. Enrich each pending item with its table context.
    final result = <PendingRadarItem>[];
    for (final itemModel in pendingModels) {
      final session = sessionMap[itemModel.tableSessionId];
      if (session == null || !session.status.isActive) continue;
      result.add(
        PendingRadarItem(
          item: itemModel.toEntity(),
          tableNumber: session.tableNumber,
          tableApodo: session.apodo,
        ),
      );
    }

    return result;
  }
}

// ── Mapper extensions ──────────────────────────────────────────────────────────

extension _TableSessionMapper on TableSession {
  TableSessionEntity toEntity() => TableSessionEntity(
        id: id,
        tableNumber: tableNumber,
        apodo: apodo,
        status: status,
        openedAt: openedAt,
        closedAt: closedAt,
        verificationCode: verificationCode,
      );
}

extension _OrderItemMapper on OrderItem {
  OrderItemEntity toEntity() => OrderItemEntity(
        id: id,
        tableSessionId: tableSessionId,
        productName: productName,
        productCatalogId: productCatalogId,
        price: price,
        quantity: quantity,
        category: category,
        orderedAt: orderedAt,
        deliveredAt: deliveredAt,
        status: status,
        isPaid: isPaid,
        paymentReceiptId: paymentReceiptId,
        note: note,
        menuCategory: menuCategory,
        subcategory: subcategory,
      );
}

// ── TableStatus extension (for isActive helper) ───────────────────────────────

extension _TableStatusX on TableStatus {
  bool get isActive =>
      this == TableStatus.open || this == TableStatus.partiallyPaid;
}
