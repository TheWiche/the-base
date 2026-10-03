import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../base_management/domain/entities/wallet_summary.dart';
import '../../../base_management/presentation/providers/base_wallet_providers.dart';
import '../../../payments/domain/entities/payment_receipt_entity.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/i_dashboard_repository.dart';

// ── Dependency injection ───────────────────────────────────────────────────────

final dashboardRepositoryProvider = Provider<IDashboardRepository>(
  (ref) => DashboardRepositoryImpl(),
);

// ── Transfer receipt stream ────────────────────────────────────────────────────

/// All transfer receipts, newest first. Feeds both the legalization tabs and
/// the wallet enrichment providers below.
final allTransferReceiptsProvider =
    StreamProvider<List<PaymentReceiptEntity>>((ref) {
  return ref.read(dashboardRepositoryProvider).watchTransferReceipts();
});

/// Pending transfers: captured but not yet verified by the cashier.
final pendingTransfersProvider =
    Provider<List<PaymentReceiptEntity>>((ref) {
  return ref.watch(allTransferReceiptsProvider).maybeWhen(
        data: (receipts) => receipts.where((r) => !r.isLegalizedInCaja).toList(),
        orElse: () => [],
      );
});

/// Legalized transfers: the cashier confirmed these in the register.
final legalizedTransfersProvider =
    Provider<List<PaymentReceiptEntity>>((ref) {
  return ref.watch(allTransferReceiptsProvider).maybeWhen(
        data: (receipts) => receipts.where((r) => r.isLegalizedInCaja).toList(),
        orElse: () => [],
      );
});

// ── Derived totals (computed from the same stream — one Isar subscription) ────

/// Sum of [amountPaid] for legalized transfer receipts.
/// Feeds [WalletSummary.verifiedTransfersTotal] for Available Balance.
final verifiedTransfersTotalProvider = Provider<int>((ref) {
  return ref.watch(allTransferReceiptsProvider).maybeWhen(
        data: (receipts) => receipts
            .where((r) => r.isLegalizedInCaja)
            .fold(0, (sum, r) => sum + r.amountPaid),
        orElse: () => 0,
      );
});

/// Sum of [tipAmount] for all transfer receipts (legalized or not).
/// Feeds [WalletSummary.transferTipsTotal] for Net Profit.
final transferTipsTotalProvider = Provider<int>((ref) {
  return ref.watch(allTransferReceiptsProvider).maybeWhen(
        data: (receipts) =>
            receipts.fold(0, (sum, r) => sum + r.tipAmount),
        orElse: () => 0,
      );
});

/// Running sum of served standard item costs from [OrderItem] collection.
/// Feeds [WalletSummary.servedStandardItemsTotal] for Available Balance.
final servedStandardItemsTotalProvider = StreamProvider<int>((ref) {
  return ref.read(dashboardRepositoryProvider).watchServedStandardItemsTotal();
});

/// Running sum of net cash received from cash payments (amountPaid − changeGiven).
/// Feeds [WalletSummary.cashPaymentsTotal] for Available Balance.
/// Cash is counted immediately on receipt — no legalization step required.
final cashPaymentsTotalProvider = StreamProvider<int>((ref) {
  return ref.read(dashboardRepositoryProvider).watchCashPaymentsTotal();
});

// ── Enriched wallet summary ────────────────────────────────────────────────────

/// The complete [WalletSummary] with all cross-feature integrations applied.
///
/// Derives from [baseWalletProvider] and injects:
///   • [verifiedTransfersTotal]  → fills [WalletSummary.verifiedTransfersTotal]
///   • [cashPaymentsTotal]       → fills [WalletSummary.cashPaymentsTotal]
///   • [transferTipsTotal]       → fills [WalletSummary.transferTipsTotal]
///   • [servedStandardItemsTotal]→ fills [WalletSummary.servedStandardItemsTotal]
///
/// [BaseWalletScreen] should watch this provider instead of [baseWalletProvider]
/// so the Available Balance and Net Profit reflect real-time payment data.
///
/// Reactivity chain on cash payment:
///   recordPayment(cash) → Isar write → [cashPaymentsTotalProvider] re-emits →
///   this provider recomputes → [BaseWalletScreen] shows updated Available Balance.
///
/// Reactivity chain on "Cobrado en Caja":
///   legalizeTransfer() → Isar write → [allTransferReceiptsProvider] re-emits →
///   [verifiedTransfersTotalProvider] recomputes → this provider recomputes →
///   [BaseWalletScreen] shows updated Available Balance.
final enrichedWalletSummaryProvider =
    Provider<AsyncValue<WalletSummary>>((ref) {
  final baseAsync = ref.watch(baseWalletProvider);
  final verifiedTotal = ref.watch(verifiedTransfersTotalProvider);
  final tipsTotal = ref.watch(transferTipsTotalProvider);
  final servedAsync = ref.watch(servedStandardItemsTotalProvider);
  final servedTotal = servedAsync.valueOrNull ?? 0;
  final cashAsync = ref.watch(cashPaymentsTotalProvider);
  final cashTotal = cashAsync.valueOrNull ?? 0;

  return baseAsync.whenData(
    (base) => base.copyWith(
      verifiedTransfersTotal: verifiedTotal,
      cashPaymentsTotal: cashTotal,
      transferTipsTotal: tipsTotal,
      servedStandardItemsTotal: servedTotal,
    ),
  );
});

// ── Legalization notifier ─────────────────────────────────────────────────────

/// Handles the "Cobrado en Caja" action.
///
/// On success the Isar stream fires, [allTransferReceiptsProvider] re-emits,
/// and the wallet enrichment updates — no manual state patching required.
class LegalizationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> legalizeTransfer(int receiptId) async {
    state = const AsyncLoading();
    final result = await ref
        .read(dashboardRepositoryProvider)
        .legalizeTransfer(receiptId);
    state = const AsyncData(null);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => failure,
    };
  }
}

final legalizationProvider =
    AsyncNotifierProvider<LegalizationNotifier, void>(
  LegalizationNotifier.new,
);
