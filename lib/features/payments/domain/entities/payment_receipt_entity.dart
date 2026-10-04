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
        TransferMethod.nequi => 'Transferencia',
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
    this.isGeneralAdvance = false,
    this.transactionGroupId,
    this.note,
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

  final bool isGeneralAdvance;
  final String? transactionGroupId;
  final String? note;

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
/// Supports item-based payments and arbitrary general advances.
/// Only [PaymentMethod.cash] and [PaymentMethod.transfer] are accepted.
final class RecordPaymentParams {
  const RecordPaymentParams({
    required this.tableSessionId,
    this.selectedItemIds = const [],
    required this.amountPaid,
    required this.billSubtotal,
    required this.paymentMethod,
    this.selectedQuantities = const {},
    this.transferMethod,
    this.photoSourcePath,
    this.tipAmount = 0,
    this.isGeneralAdvance = false,
    @Deprecated('Mixed payments are no longer supported. Do not set to true.')
    this.isMixed = false,
    @Deprecated('Mixed payments are no longer supported.')
    this.cashAmount,
    @Deprecated('Mixed payments are no longer supported.')
    this.transferAmount,
    @Deprecated('Mixed payments are no longer supported.')
    this.mixedTransferMethod,
    @Deprecated('Mixed payments are no longer supported.')
    this.mixedPhotoSourcePath,
    this.note,
  })  : assert(
          isMixed || paymentMethod != PaymentMethod.transfer || photoSourcePath != null,
          'Transfer payments require a photoSourcePath.',
        ),
        assert(
          isMixed || paymentMethod != PaymentMethod.transfer || transferMethod != null,
          'Transfer payments require a transferMethod.',
        ),
        assert(
          !isMixed || (cashAmount != null && transferAmount != null && mixedPhotoSourcePath != null && mixedTransferMethod != null),
          'Mixed payments require cashAmount, transferAmount, mixedTransferMethod, and mixedPhotoSourcePath.',
        );

  final int tableSessionId;
  final List<int> selectedItemIds;

  /// itemId → units being paid now.
  final Map<int, int> selectedQuantities;

  /// What the customer actually handed over or transferred (COP).
  final int amountPaid;

  /// Sum of selected item lineTotals, or arbitrary advance target amount.
  final int billSubtotal;

  final PaymentMethod paymentMethod;
  final TransferMethod? transferMethod;

  /// Temp file path from ImagePicker (already JPEG-compressed).
  final String? photoSourcePath;

  /// Explicit tip from the customer (transfers only). Default 0.
  final int tipAmount;

  /// True when this payment is an arbitrary general advance to the table.
  final bool isGeneralAdvance;

  /// True when this transaction is a simultaneous mixed payment (Cash + Transfer).
  final bool isMixed;

  /// Cash portion in a mixed transaction.
  final int? cashAmount;

  /// Transfer portion in a mixed transaction.
  final int? transferAmount;

  /// Transfer method platform for the transfer portion of a mixed transaction.
  final TransferMethod? mixedTransferMethod;

  /// Image path for the transfer portion of a mixed transaction.
  final String? mixedPhotoSourcePath;

  final String? note;

  /// Cash change owed back to the customer.
  /// Always 0 for pure transfer payments.
  int get changeGiven =>
      (paymentMethod == PaymentMethod.cash || isMixed) && amountPaid > billSubtotal
          ? amountPaid - billSubtotal
          : 0;
}
