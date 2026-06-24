import 'package:isar/isar.dart';

import '../../../../core/database/isar_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../billing/data/models/payment_receipt.dart';
import '../../../orders/data/models/order_item.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../payments/domain/entities/payment_receipt_entity.dart';
import '../../domain/repositories/i_dashboard_repository.dart';

/// Isar-backed implementation of [IDashboardRepository].
///
/// ── Single subscription per collection ───────────────────────────────────────
/// Both [watchTransferReceipts] and [watchServedStandardItemsTotal] use
/// [watchLazy] to subscribe to their respective collections. Each emits on
/// every write to that collection — including writes from other features
/// ([PaymentRepositoryImpl], [OrderRepositoryImpl]).
///
/// ── Mapping ───────────────────────────────────────────────────────────────────
/// [PaymentReceipt] → [PaymentReceiptEntity] via [_mapReceipt].
/// No domain objects are stored in Isar — only primitives and Isar types.
final class DashboardRepositoryImpl implements IDashboardRepository {
  Isar get _db => IsarService.db;

  // ── Reactive reads ─────────────────────────────────────────────────────────

  @override
  Stream<List<PaymentReceiptEntity>> watchTransferReceipts() {
    return _db.paymentReceipts
        .watchLazy(fireImmediately: true)
        .asyncMap((_) async {
      final models = await _db.paymentReceipts
          .filter()
          .paymentMethodEqualTo(PaymentMethod.transfer)
          .sortByPaidAtDesc()
          .findAll();
      return models.map(_mapReceipt).toList();
    });
  }

  @override
  Stream<int> watchServedStandardItemsTotal() {
    return _db.orderItems
        .watchLazy(fireImmediately: true)
        .asyncMap((_) async {
      final models = await _db.orderItems
          .filter()
          .categoryEqualTo(ProductCategory.standard)
          .statusEqualTo(OrderItemStatus.delivered)
          .findAll();
      return models.fold<int>(0, (sum, item) => sum + item.price * item.quantity);
    });
  }

  @override
  Stream<int> watchCashPaymentsTotal() {
    return _db.paymentReceipts
        .watchLazy(fireImmediately: true)
        .asyncMap((_) async {
      final models = await _db.paymentReceipts
          .filter()
          .paymentMethodEqualTo(PaymentMethod.cash)
          .findAll();
      return models.fold<int>(
        0,
        (sum, m) => sum + m.amountPaid - m.changeGiven,
      );
    });
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> legalizeTransfer(int receiptId) async {
    try {
      await IsarService.write((db) async {
        final receipt = await db.paymentReceipts.get(receiptId);
        if (receipt == null) {
          throw StateError('PaymentReceipt $receiptId not found.');
        }
        receipt.isLegalizedInCaja = true;
        await db.paymentReceipts.put(receipt);
      });
      return const Ok(null);
    } on StateError catch (e) {
      return Err(NotFoundFailure(message: e.message));
    } catch (e, st) {
      return Err(
        DatabaseFailure(
          message: 'Error al legalizar la transferencia: $e',
          stackTrace: st,
        ),
      );
    }
  }

  // ── Mapper ─────────────────────────────────────────────────────────────────

  PaymentReceiptEntity _mapReceipt(PaymentReceipt m) => PaymentReceiptEntity(
        id: m.id,
        tableSessionId: m.tableSessionId,
        amountPaid: m.amountPaid,
        changeGiven: m.changeGiven,
        tipAmount: m.tipAmount,
        paymentMethod: m.paymentMethod,
        transferMethod: m.transferMethodIndex != null
            ? TransferMethod.values[m.transferMethodIndex!]
            : null,
        photoPath: m.photoPath,
        isLegalizedInCaja: m.isLegalizedInCaja,
        verificationCode: m.verificationCode,
        paidAt: m.paidAt,
      );
}
