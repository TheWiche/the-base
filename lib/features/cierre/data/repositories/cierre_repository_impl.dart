import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../../../core/database/isar_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../base_management/data/models/waiter_base_transaction.dart';
import '../../../base_management/domain/entities/wallet_summary.dart';
import '../../../billing/data/models/payment_receipt.dart';
import '../../../orders/data/models/order_item.dart';
import '../../../shift_history/data/models/shift_snapshot.dart';
import '../../../tables/data/models/table_session.dart';
import '../../domain/repositories/i_cierre_repository.dart';

/// Isar-backed implementation of [ICierreRepository].
///
/// [finalizeShift] saves a [ShiftSnapshot] then clears all operational
/// collections — leaving [ShiftSnapshot] intact so the history accumulates.
/// This is safe because Cierre Blindado validation guarantees no pending items,
/// no open sessions, and no unlegalized transfers before this point.
final class CierreRepositoryImpl implements ICierreRepository {
  @override
  Future<Result<void>> finalizeShift({
    required WalletSummary summary,
    required int cashInHand,
  }) async {
    try {
      final now = DateTime.now();
      final snapshot = ShiftSnapshot()
        ..snapshotAt = now
        ..initialBase = summary.initialBase
        ..totalIncreases = summary.totalIncreases
        ..totalDecreases = summary.totalDecreases
        ..totalLiquorDebt = summary.totalLiquorDebt
        ..verifiedTransfersTotal = summary.verifiedTransfersTotal
        ..cashPaymentsTotal = summary.cashPaymentsTotal
        ..servedStandardItemsTotal = summary.servedStandardItemsTotal
        ..transferTipsTotal = summary.transferTipsTotal
        ..cashInHand = cashInHand
        ..totalDebt = summary.totalDebt
        ..availableBalance = summary.availableBalance
        ..netProfit = summary.netProfit;

      await IsarService.write((db) async {
        // 1. Persist the snapshot BEFORE clearing.
        await db.shiftSnapshots.put(snapshot);

        // 2. Clear all operational collections, keeping ShiftSnapshot intact.
        //    NOTE: products are static reference data (menu + agotados +
        //    ediciones del CRUD) — NO se borran, así persisten entre turnos.
        await db.waiterBaseTransactions.clear();
        await db.tableSessions.clear();
        await db.orderItems.clear();
        await db.paymentReceipts.clear();
      });

      debugPrint('[CierreRepo] Shift finalized and snapshot saved (id: ${snapshot.id}).');
      return const Ok(null);
    } on IsarError catch (e, st) {
      return Err(DatabaseFailure(message: e.message, stackTrace: st));
    } catch (e, st) {
      return Err(
        DatabaseFailure(
          message: 'Error inesperado al finalizar jornada: $e',
          stackTrace: st,
        ),
      );
    }
  }
}
