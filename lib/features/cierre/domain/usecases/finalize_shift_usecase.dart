import '../../../../core/errors/result.dart';
import '../../../base_management/domain/entities/wallet_summary.dart';
import '../repositories/i_cierre_repository.dart';

/// Delegates the shift-finalization to [ICierreRepository].
///
/// Validation (Cierre Blindado) is done by [cierreValidationProvider] in the
/// presentation layer before the UI allows calling this use case. This class
/// therefore performs no additional validation — the pre-condition is met by
/// the time `call()` is invoked.
final class FinalizeShiftUseCase {
  const FinalizeShiftUseCase(this._repository);

  final ICierreRepository _repository;

  Future<Result<void>> call({
    required WalletSummary summary,
    required int cashInHand,
  }) =>
      _repository.finalizeShift(summary: summary, cashInHand: cashInHand);
}
