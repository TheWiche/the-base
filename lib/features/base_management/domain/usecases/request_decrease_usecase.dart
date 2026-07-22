import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/base_transaction_entity.dart';
import '../repositories/i_base_repository.dart';

/// Records a $100,000 COP base reduction with the exact current timestamp.
///
/// ── Business rules enforced ──────────────────────────────────────────────────
/// 1. The shift must be initialized ([hasInitialBase()] == true).
/// 2. Net increases must exceed net decreases — prevents reducing below the
///    original $300,000 initial base the waiter committed at shift start.
/// 3. The amount is always exactly $100,000 (same step as increases).
/// 4. Timestamp captured inside the repository at write time.
///
/// ── Financial effect ─────────────────────────────────────────────────────────
/// Reduces [WalletSummary.baseCapital], [WalletSummary.totalDebt], AND
/// [WalletSummary.availableBalance] by $100,000 — the inverse of an increase.
final class RequestDecreaseUseCase {
  const RequestDecreaseUseCase(this._repository);

  final IBaseRepository _repository;

  Future<Result<BaseTransactionEntity>> call({required int amount}) async {
    final isInitialized = await _repository.hasInitialBase();
    if (!isInitialized) {
      return const Err(
        BusinessRuleFailure(
          message: 'Debes iniciar el turno antes de reducir la base.',
        ),
      );
    }

    final txResult = await _repository.getAllTransactions();
    if (txResult case Err(:final failure)) {
      return Err(failure);
    }
    final txs = (txResult as Ok<List<BaseTransactionEntity>>).value;

    int netIncreases = 0;
    for (final t in txs) {
      if (t.type == TransactionType.increase) netIncreases += t.amount;
      if (t.type == TransactionType.decrease) netIncreases -= t.amount;
    }

    if (netIncreases <= 0) {
      return const Err(
        BusinessRuleFailure(
          message: 'No hay incrementos disponibles para reducir.',
        ),
      );
    }

    return _repository.requestDecrease(amount: amount);
  }
}
