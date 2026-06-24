import 'package:isar/isar.dart';

// Enums are defined in the DOMAIN layer — data → domain import is correct.
import '../../../payments/domain/entities/payment_receipt_entity.dart';
import '../../../tables/data/models/table_session.dart';

part 'payment_receipt.g.dart';

/// Isar collection recording a single payment event for a [TableSession].
///
/// A receipt can be PARTIAL (split billing) or FULL (closes the table).
/// Multiple receipts per session are the norm, not the exception.
///
/// ── Payment method routing ───────────────────────────────────────────────────
///   [PaymentMethod.cash]     → [changeGiven] is calculated and stored.
///                              No photo required. Immediately contributes to
///                              Available Balance.
///   [PaymentMethod.transfer] → [photoPath] MUST be non-null (camera flow).
///                              [isLegalizedInCaja] starts false.
///                              Only contributes to Available Balance AFTER
///                              [isLegalizedInCaja] is set to true by the cashier.
///
/// ── Cierre Blindado dependency ───────────────────────────────────────────────
/// The daily report generator queries:
///   WHERE paymentMethod == transfer AND isLegalizedInCaja == false
/// If any row matches, the Cierre is BLOCKED.
///
/// ── Tips ─────────────────────────────────────────────────────────────────────
/// [tipAmount] is always 0 for cash (tips from cash are already in the
/// physical envelope). For transfers, the customer may explicitly add a tip
/// to the transfer total — stored here and added to Net Profit calculation.
///
/// ── Verification ─────────────────────────────────────────────────────────────
/// [verificationCode] is an 8-digit SHA-256-derived code generated at payment
/// time. The cashier enters this code when legalizing the transfer receipt in
/// the register, providing an audit trail without exposing raw amounts.
@collection
class PaymentReceipt {
  Id id = Isar.autoIncrement;

  // ── Parent reference ───────────────────────────────────────────────────────

  /// FK to the owning [TableSession].
  /// Indexed for "all payments for table X" queries.
  @Index()
  late int tableSessionId;

  // ── Amount fields ──────────────────────────────────────────────────────────

  /// Total amount the customer handed over or transferred (COP).
  /// For cash: may exceed the bill → [changeGiven] covers the difference.
  /// For transfers: must equal the bill total (no overpayment).
  late int amountPaid;

  /// Cash returned to the customer (COP). Always 0 for transfers.
  /// Formula: changeGiven = amountPaid − billSubtotal (when amountPaid > bill).
  late int changeGiven;

  /// Explicit tip included in this payment (COP).
  /// For cash receipts: always 0 (cash tips are not tracked digitally).
  /// For transfers: the customer may add a tip to the transferred amount.
  late int tipAmount;

  // ── Payment method ─────────────────────────────────────────────────────────

  /// Primary payment channel.
  @enumerated
  late PaymentMethod paymentMethod;

  /// Transfer platform stored as enum index.
  /// Non-null only when [paymentMethod] is [PaymentMethod.transfer].
  /// Mapped to/from [TransferMethod] by the repository.
  int? transferMethodIndex;

  // ── Transfer-specific fields ───────────────────────────────────────────────

  /// Absolute local file path to the transfer proof photo.
  ///
  /// Non-null invariant: if [paymentMethod] == [PaymentMethod.transfer],
  /// this field MUST be set before the receipt is persisted.
  ///
  /// The file is saved in the device's "Bonanza_Transferencias" folder
  /// for easy bulk deletion by the owner.
  String? photoPath;

  /// Cloud URL after the photo is uploaded to Supabase Storage.
  /// Set asynchronously after [photoPath] is confirmed on-device.
  /// May remain null if the device is offline at payment time — the sync
  /// service retries in the background.
  String? supabasePhotoUrl;

  /// Whether the cashier has cross-verified this transfer in the register.
  ///
  /// Starts as [false] for all transfers.
  /// Cierre Blindado BLOCKS the daily report if ANY transfer row has
  /// this field as [false].
  ///
  /// Indexed for the Cierre Blindado check:
  ///   WHERE paymentMethod == transfer AND isLegalizedInCaja == false
  @Index()
  late bool isLegalizedInCaja;

  /// 8-digit numeric code for cashier verification.
  /// Derived via SHA-256(sessionId + amountPaid + paidAt.ms).
  /// The cashier enters this code when marking the transfer as legalized.
  String? verificationCode;

  // ── Audit timestamp ────────────────────────────────────────────────────────

  /// When the payment was recorded. Indexed for daily report date filtering.
  @Index()
  late DateTime paidAt;

  // ── Back-link ──────────────────────────────────────────────────────────────

  /// Navigates back to the owning [TableSession] without an extra query.
  /// Must call `.load()` before accessing.
  ///
  /// Mapped to [TableSession.payments].
  @Backlink(to: 'payments')
  final tableSession = IsarLink<TableSession>();
}

// PaymentMethod and TransferMethod are imported from:
// lib/features/payments/domain/entities/payment_receipt_entity.dart
// Do NOT redefine them here — the Isar @enumerated annotation stores the
// enum index, and both enum declarations must stay in sync.
