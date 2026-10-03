import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../../core/database/isar_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../billing/data/models/payment_receipt.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/billing_selection.dart';
import '../../domain/entities/payment_receipt_entity.dart';
import '../../domain/repositories/i_payment_repository.dart';
import '../../domain/usecases/record_payment_usecase.dart';

// ── Dependency injection ───────────────────────────────────────────────────────

final paymentRepositoryProvider = Provider<IPaymentRepository>(
  (ref) => PaymentRepositoryImpl(),
);

final recordPaymentUseCaseProvider = Provider<RecordPaymentUseCase>(
  (ref) => RecordPaymentUseCase(ref.read(paymentRepositoryProvider)),
);

// ── Billing selection state ────────────────────────────────────────────────────

/// Manages which items the waiter has checked for a specific billing session.
///
/// Scoped per session via the family modifier so that navigating back and forth
/// between tables does not bleed selection state. [autoDispose] clears the
/// selection when the [BillingScreen] leaves the widget tree.
class BillingSelectionNotifier
    extends StateNotifier<BillingSelection> {
  BillingSelectionNotifier() : super(const BillingSelection());

  /// Toggle a whole line in (at [maxQty] units) or out.
  void toggle(int itemId, int maxQty) =>
      state = state.toggle(itemId, maxQty);

  /// Set how many units of [itemId] to pay now.
  void setQuantity(int itemId, int qty) =>
      state = state.setQuantity(itemId, qty);

  void selectAll(Map<int, int> idToQty) => state = state.selectAll(idToQty);
  void clearAll() => state = state.clearAll();
}

final billingSelectionProvider = StateNotifierProvider.family
    .autoDispose<BillingSelectionNotifier, BillingSelection, int>(
  (ref, sessionId) => BillingSelectionNotifier(),
);

// ── Payment action notifier ────────────────────────────────────────────────────

/// Thin async wrapper around [RecordPaymentUseCase].
///
/// Holds [AsyncValue.loading] during the payment write so that buttons can
/// disable themselves. Actions return [Failure?] (null = success) to avoid
/// clobbering state on error.
class PaymentNotifier extends AsyncNotifier<PaymentReceiptEntity?> {
  @override
  Future<PaymentReceiptEntity?> build() async => null;

  Future<Failure?> recordPayment(RecordPaymentParams params) async {
    state = const AsyncLoading();
    final result =
        await ref.read(recordPaymentUseCaseProvider).call(params);
    return switch (result) {
      Ok(:final value) => _setSuccess(value),
      Err(:final failure) => _setError(failure),
    };
  }

  Failure? _setSuccess(PaymentReceiptEntity entity) {
    state = AsyncData(entity);
    return null;
  }

  Failure? _setError(Failure failure) {
    state = AsyncError(failure, StackTrace.current);
    return failure;
  }
}

final paymentNotifierProvider =
    AsyncNotifierProvider<PaymentNotifier, PaymentReceiptEntity?>(
  PaymentNotifier.new,
);

// ── Navigation args ────────────────────────────────────────────────────────────

/// Value object passed via GoRouter [extra] from [BillingScreen] to the
/// cash, transfer, and mixed payment sub-screens.
final class PaymentNavigationArgs {
  const PaymentNavigationArgs({
    required this.sessionId,
    this.selectedItemIds = const [],
    this.selectedQuantities = const {},
    required this.billSubtotal,
    this.isGeneralAdvance = false,
  });

  final int sessionId;
  final List<int> selectedItemIds;

  /// itemId → units to pay. Drives partial (per-unit) payment splitting.
  final Map<int, int> selectedQuantities;
  final int billSubtotal;
  final bool isGeneralAdvance;
}

// ── Per-session financial providers ──────────────────────────────────────────

/// Stream of all payment receipts for a specific table session, newest first.
final sessionPaymentsProvider =
    StreamProvider.family<List<PaymentReceiptEntity>, int>((ref, sessionId) {
  final isar = IsarService.db;
  return isar.paymentReceipts
      .watchLazy(fireImmediately: true)
      .asyncMap((_) async {
    final models = await isar.paymentReceipts
        .filter()
        .tableSessionIdEqualTo(sessionId)
        .sortByPaidAtDesc()
        .findAll();
    return models
        .map((m) => PaymentReceiptEntity(
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
              isGeneralAdvance: m.isGeneralAdvance,
              transactionGroupId: m.transactionGroupId,
              note: m.note,
              paidAt: m.paidAt,
            ))
        .toList();
  });
});

class TableFinancialSummary {
  const TableFinancialSummary({
    required this.totalAccount,
    required this.totalPaid,
    required this.pendingBalance,
    required this.isFullyPaid,
  });

  final int totalAccount;
  final int totalPaid;
  final int pendingBalance;
  final bool isFullyPaid;
}

/// Computes the complete financial snapshot for a table session:
/// total consumed, total paid/advance received, and net pending balance.
final tableFinancialSummaryProvider =
    Provider.family<TableFinancialSummary, int>((ref, sessionId) {
  final itemsAsync = ref.watch(tableOrderProvider(sessionId));
  final paymentsAsync = ref.watch(sessionPaymentsProvider(sessionId));

  final items = itemsAsync.valueOrNull ?? [];
  final activeItems = items.where((i) => !i.isCancelled);
  final totalAccount = activeItems.fold<int>(0, (s, i) => s + i.lineTotal);

  final payments = paymentsAsync.valueOrNull ?? [];
  final totalPaid = payments.fold<int>(0, (s, p) => s + p.netReceived);

  final pendingBalance =
      (totalAccount - totalPaid).clamp(0, double.maxFinite.toInt());
  final isFullyPaid = totalAccount > 0 && totalPaid >= totalAccount;

  return TableFinancialSummary(
    totalAccount: totalAccount,
    totalPaid: totalPaid,
    pendingBalance: pendingBalance,
    isFullyPaid: isFullyPaid,
  );
});

/// Reactive sum of [TableFinancialSummary.pendingBalance] across ALL active
/// table sessions. Used by [TablesScreen] to display the "Total en Mesas"
/// header indicator.
///
/// Re-evaluates whenever any session's items or payments change. Derived
/// purely from already-watched streams — no extra Isar queries.
final totalPendingInTablesProvider = Provider<int>((ref) {
  final sessions =
      ref.watch(activeSessionsProvider).valueOrNull ?? [];
  return sessions.fold<int>(0, (sum, session) {
    final summary = ref.watch(tableFinancialSummaryProvider(session.id));
    return sum + summary.pendingBalance;
  });
});
