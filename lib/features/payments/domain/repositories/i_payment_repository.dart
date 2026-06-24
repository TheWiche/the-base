import '../../../../core/errors/result.dart';
import '../entities/payment_receipt_entity.dart';

/// Contract for all payment persistence operations.
///
/// The implementation ([PaymentRepositoryImpl]) handles:
///   • Photo file copy to "Bonanza_Transferencias" (atomic with the Isar write).
///   • Single Isar write transaction covering PaymentReceipt + OrderItems + TableSession.
///   • SHA-256 verification code generation for transfers.
///   • Background Supabase upload (fire-and-forget, does not block payment).
abstract interface class IPaymentRepository {
  /// Records a payment atomically.
  ///
  /// For transfer payments, [RecordPaymentParams.photoSourcePath] (the temp
  /// camera file) is first copied to the "Bonanza_Transferencias" device
  /// directory. Only if that succeeds does the Isar write begin.
  ///
  /// The Isar write is a single [writeTxn] covering:
  ///   1. [PaymentReceipt] creation.
  ///   2. Selected [OrderItem] records marked paid.
  ///   3. [TableSession.status] updated to [partiallyPaid] or [closed].
  ///
  /// Returns [Ok] with the created entity, or [Err] with a [Failure] subtype.
  Future<Result<PaymentReceiptEntity>> recordPayment(RecordPaymentParams params);
}
