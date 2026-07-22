import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/base_transaction_entity.dart';
import '../repositories/i_base_repository.dart';

/// Records a $100,000 COP base increase with the exact current timestamp.
///
/// ── Business rules enforced ──────────────────────────────────────────────────
/// 1. The shift must be initialized ([hasInitialBase()] == true).
///    Increases cannot exist without an initial base — they compound it.
/// 2. The amount is always exactly [FinancialConstants.baseIncrement] ($100,000).
///    Variable amounts are not supported by the business model.
/// 3. The timestamp is captured inside the repository at write time using
///    [DateTime.now()], ensuring no client-side clock manipulation is possible
///    at the use case call site.
///
/// ── Financial effect ─────────────────────────────────────────────────────────
/// Increases both [WalletSummary.totalDebt] AND [WalletSummary.availableBalance]
/// by $100,000 — unlike liquor adjustments, which only affect [totalDebt].
final class RequestIncreaseUseCase {
  const RequestIncreaseUseCase(this._repository);

  final IBaseRepository _repository;

  Future<Result<BaseTransactionEntity>> call({required int amount}) async {
    // Guard: increases require an initialized shift.
    final isInitialized = await _repository.hasInitialBase();
    if (!isInitialized) {
      return Err(
        const BusinessRuleFailure(
          message: 'Debes iniciar el turno antes de solicitar un incremento.',
        ),
      );
    }

    return _repository.requestIncrease(amount: amount);
  }
}
