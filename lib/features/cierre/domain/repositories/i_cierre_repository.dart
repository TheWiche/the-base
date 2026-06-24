import '../../../../core/errors/result.dart';
import '../../../base_management/domain/entities/wallet_summary.dart';

/// Defines the contract for shift-close operations.
abstract interface class ICierreRepository {
  /// Saves a [ShiftSnapshot] and wipes all operational data for the closed shift.
  ///
  /// Precondition (enforced by Cierre Blindado validation before this is called):
  ///   • All table sessions are closed
  ///   • All radar items are delivered
  ///   • All transfers are legalized
  ///
  /// Clears: [TableSession], [OrderItem], [PaymentReceipt], [WaiterBaseTransaction], [Product].
  /// Preserves: [ShiftSnapshot] — history accumulates across shifts.
  Future<Result<void>> finalizeShift({
    required WalletSummary summary,
    required int cashInHand,
  });
}
