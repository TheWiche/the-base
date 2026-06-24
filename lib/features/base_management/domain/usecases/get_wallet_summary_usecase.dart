import '../entities/wallet_summary.dart';
import '../repositories/i_base_repository.dart';

/// Transforms the raw transaction stream from the repository into a
/// continuously-updated [WalletSummary] stream.
///
/// The presentation layer subscribes to [call()] via the Riverpod notifier.
/// Every Isar write triggers a new emission, which rebuilds the UI atomically.
///
/// This use case owns the single application of [WalletSummary.fromTransactions].
/// All formula logic lives in the entity — the use case only orchestrates.
final class GetWalletSummaryUseCase {
  const GetWalletSummaryUseCase(this._repository);

  final IBaseRepository _repository;

  /// Returns a broadcast stream of [WalletSummary] that emits:
  ///   1. Immediately on subscription (current state).
  ///   2. Whenever any [WaiterBaseTransaction] is written or deleted in Isar.
  ///
  /// The stream never completes — it lives as long as the Riverpod notifier
  /// is alive. Errors from Isar are propagated as stream errors.
  Stream<WalletSummary> call() {
    return _repository
        .watchTransactions()
        .map(WalletSummary.fromTransactions);
  }
}
