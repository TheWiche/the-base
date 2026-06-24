import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
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
/// cash and transfer payment sub-screens.
final class PaymentNavigationArgs {
  const PaymentNavigationArgs({
    required this.sessionId,
    required this.selectedItemIds,
    required this.selectedQuantities,
    required this.billSubtotal,
  });

  final int sessionId;
  final List<int> selectedItemIds;

  /// itemId → units to pay. Drives partial (per-unit) payment splitting.
  final Map<int, int> selectedQuantities;
  final int billSubtotal;
}
