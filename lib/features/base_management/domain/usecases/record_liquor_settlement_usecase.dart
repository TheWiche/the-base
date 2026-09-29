import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../entities/base_transaction_entity.dart';
import '../repositories/i_base_repository.dart';

/// Records a payment of liquor debt handed over directly in cash to the
/// establishment's cash register during the shift.
///
/// ── Business rules enforced ──────────────────────────────────────────────────
/// 1. The shift must be initialized ([hasInitialBase()] == true).
/// 2. Amount must be positive (> 0).
/// 3. Current net liquor debt must be positive (> 0).
/// 4. Amount cannot exceed current net liquor debt.
/// 5. Timestamp is captured in repository at write time.
///
/// ── Financial effect ─────────────────────────────────────────────────────────
/// Reduces [WalletSummary.totalLiquorDebt] and consequently [WalletSummary.totalDebt].
/// Does NOT touch [WalletSummary.availableBalance] or waiter's physical pouch,
/// as bottles are paid directly to the venue's register (pass-through).
final class RecordLiquorSettlementUseCase {
  const RecordLiquorSettlementUseCase(this._repository);

  final IBaseRepository _repository;

  Future<Result<BaseTransactionEntity>> call({
    required int amount,
    String? note,
  }) async {
    if (amount <= 0) {
      return const Err(
        BusinessRuleFailure(
          message: 'El monto a liquidar debe ser mayor a cero.',
        ),
      );
    }

    final isInitialized = await _repository.hasInitialBase();
    if (!isInitialized) {
      return const Err(
        BusinessRuleFailure(
          message: 'Debes iniciar el turno antes de liquidar deuda de licor.',
        ),
      );
    }

    final txResult = await _repository.getAllTransactions();
    if (txResult case Err(:final failure)) {
      return Err(failure);
    }
    final txs = (txResult as Ok<List<BaseTransactionEntity>>).value;

    int liquorDebt = 0;
    for (final t in txs) {
      if (t.type == TransactionType.liquorAdjustment) liquorDebt += t.amount;
      if (t.type == TransactionType.liquorSettlement) liquorDebt -= t.amount;
    }

    if (liquorDebt <= 0) {
      return const Err(
        BusinessRuleFailure(
          message: 'No tienes deuda pendiente por licor para liquidar.',
        ),
      );
    }

    if (amount > liquorDebt) {
      return Err(
        BusinessRuleFailure(
          message:
              'El monto (${amount.toCop}) no puede superar la deuda de licor actual (${liquorDebt.toCop}).',
        ),
      );
    }

    return _repository.recordLiquorSettlement(
      amount: amount,
      note: note,
    );
  }
}

