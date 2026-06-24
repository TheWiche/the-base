import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/base_transaction_entity.dart';
import '../repositories/i_base_repository.dart';

/// Creates the one-time $300,000 COP initial base for the current shift.
///
/// ── Business rules enforced ──────────────────────────────────────────────────
/// 1. Exactly ONE initial base may exist per shift session.
///    If one already exists, returns [BusinessRuleFailure] — no write occurs.
/// 2. The amount is always exactly [FinancialConstants.initialBase] ($300,000).
///    The repository does not accept an amount parameter.
///
/// ── Caller responsibility ────────────────────────────────────────────────────
/// The presentation layer checks the returned [Result] and surfaces a human-
/// readable message if this use case returns [Err].
final class InitializeShiftUseCase {
  const InitializeShiftUseCase(this._repository);

  final IBaseRepository _repository;

  Future<Result<BaseTransactionEntity>> call() async {
    // Guard: prevent double initialization.
    final alreadyInitialized = await _repository.hasInitialBase();
    if (alreadyInitialized) {
      return Err(
        const BusinessRuleFailure(
          message: 'El turno ya fue iniciado. '
              'No se puede crear una segunda base inicial.',
        ),
      );
    }

    return _repository.initializeShift();
  }
}
