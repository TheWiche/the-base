import '../../../../core/errors/result.dart';
import '../../../payments/domain/entities/payment_receipt_entity.dart';

/// Cross-feature data contract for the waiter dashboard.
///
/// Aggregates data from [PaymentReceipt] (billing) and [OrderItem] (orders)
/// collections to power the enriched wallet summary and legalization screen.
abstract interface class IDashboardRepository {
  /// Reactive stream of all [PaymentMethod.transfer] receipts, newest first.
  /// Used by the legalization screen and for deriving verified/pending totals.
  Stream<List<PaymentReceiptEntity>> watchTransferReceipts();

  /// Reactive stream: sum of [OrderItem.price * quantity] where
  /// category == standard AND status == delivered.
  /// Used to populate [WalletSummary.servedStandardItemsTotal].
  Stream<int> watchServedStandardItemsTotal();

  /// Reactive stream: sum of (amountPaid − changeGiven) for all cash receipts.
  /// Used to populate [WalletSummary.cashPaymentsTotal] for Available Balance.
  Stream<int> watchCashPaymentsTotal();

  /// Marks a transfer [PaymentReceipt] as legalized by the cashier.
  /// Triggers reactive re-emission of [watchTransferReceipts] → the enriched
  /// wallet summary updates automatically, injecting the legalized amount into
  /// the waiter's Available Balance without any manual refresh.
  Future<Result<void>> legalizeTransfer(int receiptId);
}
