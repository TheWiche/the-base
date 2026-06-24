import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../data/repositories/base_repository_impl.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/repositories/i_base_repository.dart';
import '../../domain/usecases/get_wallet_summary_usecase.dart';
import '../../domain/usecases/initialize_shift_usecase.dart';
import '../../domain/usecases/request_decrease_usecase.dart';
import '../../domain/usecases/request_increase_usecase.dart';

// ── Dependency Injection ───────────────────────────────────────────────────────
// Override these in tests to inject mocks without touching provider internals.

final baseRepositoryProvider = Provider<IBaseRepository>(
  (ref) => BaseRepositoryImpl(),
);

final getWalletSummaryUseCaseProvider = Provider<GetWalletSummaryUseCase>(
  (ref) => GetWalletSummaryUseCase(ref.read(baseRepositoryProvider)),
);

final initializeShiftUseCaseProvider = Provider<InitializeShiftUseCase>(
  (ref) => InitializeShiftUseCase(ref.read(baseRepositoryProvider)),
);

final requestIncreaseUseCaseProvider = Provider<RequestIncreaseUseCase>(
  (ref) => RequestIncreaseUseCase(ref.read(baseRepositoryProvider)),
);

final requestDecreaseUseCaseProvider = Provider<RequestDecreaseUseCase>(
  (ref) => RequestDecreaseUseCase(ref.read(baseRepositoryProvider)),
);

// ── Main Notifier ─────────────────────────────────────────────────────────────

/// Manages the [WalletSummary] state for the base wallet dashboard.
///
/// ── Reactivity model ─────────────────────────────────────────────────────────
/// [build()] subscribes to [GetWalletSummaryUseCase.call()], which wraps
/// Isar's [watchLazy] stream. Every write to [WaiterBaseTransaction] emits a
/// new [WalletSummary] and the Riverpod framework rebuilds all listeners.
///
/// ── Action contract ───────────────────────────────────────────────────────────
/// Write actions ([initializeShift], [requestIncrease]) return [Failure?]:
///   • null   → success (the Isar stream will deliver the updated summary).
///   • non-null → a [Failure] the UI should surface as a SnackBar/dialog.
///
/// The UI never needs to manually trigger a refresh — Isar reactivity handles it.
class BaseWalletNotifier extends AsyncNotifier<WalletSummary> {
  @override
  Future<WalletSummary> build() async {
    final useCase = ref.read(getWalletSummaryUseCaseProvider);

    // Subscribe to the Isar stream. Each emission invalidates this notifier,
    // causing build() to re-run and deliver the fresh summary to the UI.
    final subscription = useCase.call().listen(
          (summary) {
            // Only update if the notifier is still alive.
            if (!state.isLoading) state = AsyncData(summary);
          },
          onError: (Object error, StackTrace st) {
            state = AsyncError(error, st);
          },
        );

    ref.onDispose(subscription.cancel);

    // Await the first emission to satisfy the AsyncNotifier contract.
    // Subsequent emissions are handled by the listener above.
    return useCase.call().first;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Creates the $300,000 COP initial base. Returns null on success.
  Future<Failure?> initializeShift() async {
    final result = await ref.read(initializeShiftUseCaseProvider).call();
    return _handleWriteResult(result);
  }

  /// Records a $100,000 COP increase with the exact current timestamp.
  /// Returns null on success.
  Future<Failure?> requestIncrease() async {
    final result = await ref.read(requestIncreaseUseCaseProvider).call();
    return _handleWriteResult(result);
  }

  /// Records a $100,000 COP base reduction with the exact current timestamp.
  /// Returns null on success.
  Future<Failure?> requestDecrease() async {
    final result = await ref.read(requestDecreaseUseCaseProvider).call();
    return _handleWriteResult(result);
  }

  /// Called by the orders feature when a liquor item is placed.
  /// Returns null on success.
  Future<Failure?> recordLiquorAdjustment({
    required int amount,
    String? note,
  }) async {
    final result = await ref
        .read(baseRepositoryProvider)
        .recordLiquorAdjustment(amount: amount, note: note);
    return _handleWriteResult(result);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Failure? _handleWriteResult<T>(Result<T> result) {
    return switch (result) {
      Ok() => null, // success — Isar stream delivers the updated state
      Err(:final failure) => failure,
    };
  }
}

final baseWalletProvider =
    AsyncNotifierProvider<BaseWalletNotifier, WalletSummary>(
  BaseWalletNotifier.new,
);

// ── Derived providers ─────────────────────────────────────────────────────────
// Fine-grained providers so widgets only rebuild when their specific value changes.

/// Whether the current shift has been initialized.
final hasInitialBaseProvider = Provider<bool>((ref) {
  return ref.watch(baseWalletProvider).maybeWhen(
        data: (summary) => summary.hasInitialBase,
        orElse: () => false,
      );
});

/// The available balance for display in balance-only widgets.
final availableBalanceProvider = Provider<int>((ref) {
  return ref.watch(baseWalletProvider).maybeWhen(
        data: (summary) => summary.availableBalance,
        orElse: () => 0,
      );
});
