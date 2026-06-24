import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

// ── Enums (defined in DOMAIN — data model imports from here) ──────────────────

/// Primary payment channel used for a [PaymentReceiptEntity].
enum PaymentMethod {
  /// Physical cash.
  /// [PaymentReceiptEntity.changeGiven] is populated.
  /// Contributes to Available Balance immediately on receipt.
  cash,

  /// Digital transfer (Nequi, Daviplata, other).
  /// [PaymentReceiptEntity.photoPath] is REQUIRED.
  /// Only contributes to Available Balance AFTER [isLegalizedInCaja] == true.
  transfer,
}

/// Transfer platform sub-type for [PaymentMethod.transfer] receipts.
enum TransferMethod {
  nequi,
  daviplata,

  /// Any other transfer app or bank wire.
  other;

  String get displayLabel => switch (this) {
        TransferMethod.nequi => 'Nequi',
        TransferMethod.daviplata => 'Daviplata',
        TransferMethod.other => 'Otro',
      };

  Color get displayColor => switch (this) {
        TransferMethod.nequi => const Color(0xFFDA1884),    // Nequi pink
        TransferMethod.daviplata => const Color(0xFFE31837), // Daviplata red
        TransferMethod.other => AppColors.statusBlue,
      };

  IconData get displayIcon => switch (this) {
        TransferMethod.nequi => Icons.phone_android_rounded,
        TransferMethod.daviplata => Icons.phone_android_rounded,
        TransferMethod.other => Icons.account_balance_rounded,
      };
}

// ── Entity ────────────────────────────────────────────────────────────────────

/// Immutable domain entity representing one completed payment event.
/// Mapped from the [PaymentReceipt] Isar model by [PaymentRepositoryImpl].
final class PaymentReceiptEntity {
  const PaymentReceiptEntity({
    required this.id,
    required this.tableSessionId,
    required this.amountPaid,
    required this.changeGiven,
    required this.tipAmount,
    required this.paymentMethod,
    required this.isLegalizedInCaja,
    required this.paidAt,
    this.transferMethod,
    this.photoPath,
    this.verificationCode,
  });

  final int id;
  final int tableSessionId;

  /// Total amount the customer handed over or transferred (COP).
  final int amountPaid;

  /// Cash returned to the customer. Always 0 for transfers.
  final int changeGiven;

  /// Explicit tip, only meaningful for transfers. Always 0 for cash.
  final int tipAmount;

  final PaymentMethod paymentMethod;
  final TransferMethod? transferMethod;

  /// Absolute path to the transfer proof photo on the device.
  /// Non-null for all transfer receipts; null for cash.
  final String? photoPath;

  /// Whether the cashier has cross-verified this transfer in the register.
  /// Cash receipts start as true; transfers start as false.
  final bool isLegalizedInCaja;

  /// 8-digit SHA-256-derived numeric code for cashier verification (transfers only).
  final String? verificationCode;

  final DateTime paidAt;

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get isCash => paymentMethod == PaymentMethod.cash;
  bool get isTransfer => paymentMethod == PaymentMethod.transfer;

  /// Actual amount received by the waiter (amountPaid minus change given back).
  int get netReceived => amountPaid - changeGiven;
}

// ── Input DTO ─────────────────────────────────────────────────────────────────

/// Parameters for [RecordPaymentUseCase].
///
/// [billSubtotal] is pre-computed by the UI from the selected items to avoid
/// an extra database read inside the use case. The repository trusts this value.
///
/// Invariants enforced by the [assert] block:
///   • Transfer payments must supply [photoSourcePath].
///   • Transfer payments must supply [transferMethod].
final class RecordPaymentParams {
  const RecordPaymentParams({
    required this.tableSessionId,
    required this.selectedItemIds,
    required this.amountPaid,
    required this.billSubtotal,
    required this.paymentMethod,
    this.selectedQuantities = const {},
    this.transferMethod,
    this.photoSourcePath,
    this.tipAmount = 0,
  })  : assert(
          paymentMethod != PaymentMethod.transfer || photoSourcePath != null,
          'Transfer payments require a photoSourcePath.',
        ),
        assert(
          paymentMethod != PaymentMethod.transfer || transferMethod != null,
          'Transfer payments require a transferMethod.',
        );

  final int tableSessionId;
  final List<int> selectedItemIds;

  /// itemId → units being paid now. When a line's selected units are fewer than
  /// its total quantity, the repository splits the line: the paid units become a
  /// new paid OrderItem and the original line keeps the remaining units unpaid.
  /// Empty map → pay every selected line in full (legacy behavior).
  final Map<int, int> selectedQuantities;

  /// What the customer actually handed over or transferred (COP).
  final int amountPaid;

  /// Sum of selected item lineTotals, pre-calculated by the UI.
  final int billSubtotal;

  final PaymentMethod paymentMethod;
  final TransferMethod? transferMethod;

  /// Temp file path from ImagePicker (already JPEG-compressed).
  /// The repository copies this to Bonanza_Transferencias and stores the
  /// final path in [PaymentReceiptEntity.photoPath].
  final String? photoSourcePath;

  /// Explicit tip from the customer (transfers only). Default 0.
  final int tipAmount;

  /// Cash change owed back to the customer.
  /// Always 0 for transfer payments.
  int get changeGiven =>
      paymentMethod == PaymentMethod.cash && amountPaid > billSubtotal
          ? amountPaid - billSubtotal
          : 0;
}
