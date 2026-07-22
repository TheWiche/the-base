import '../../../../core/errors/result.dart';
import '../entities/base_transaction_entity.dart';

/// Abstract contract for all base-wallet data operations.
///
/// The data layer provides the concrete implementation ([BaseRepositoryImpl]).
/// The domain layer and presentation layer only depend on this interface,
/// ensuring the data source (Isar, Supabase, mock) is fully swappable.
///
/// ── Return type conventions ─────────────────────────────────────────────────
///   Reads  → [Stream] for reactive UI or [Result] for one-shot queries.
///   Writes → [Result<BaseTransactionEntity>] so callers know the persisted
///             entity (with its generated Isar ID) immediately on success.
abstract interface class IBaseRepository {
  // ── Reactive reads ─────────────────────────────────────────────────────────

  /// Emits the full transaction list whenever the Isar collection changes.
  ///
  /// The presentation layer subscribes to this stream via [GetWalletSummaryUseCase].
  /// Errors are emitted as stream errors and should be caught by the notifier.
  Stream<List<BaseTransactionEntity>> watchTransactions();

  // ── One-shot reads ─────────────────────────────────────────────────────────

  /// Returns all transactions for the current shift, sorted by timestamp ASC.
  Future<Result<List<BaseTransactionEntity>>> getAllTransactions();

  /// Returns true if at least one [TransactionType.initial] record exists.
  /// Used by use cases to guard against double-initialization.
  Future<bool> hasInitialBase();

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Creates the one-time initial base for the shift (default $300,000,
  /// configurable from Ajustes — see `financialSettingsProvider`).
  ///
  /// Precondition enforced in [InitializeShiftUseCase]: must not be called
  /// if [hasInitialBase()] is already true.
  Future<Result<BaseTransactionEntity>> initializeShift({required int amount});

  /// Records a base increase with the exact current timestamp (default
  /// $100,000, configurable from Ajustes).
  ///
  /// Precondition enforced in [RequestIncreaseUseCase]: shift must be
  /// initialized ([hasInitialBase()] == true).
  Future<Result<BaseTransactionEntity>> requestIncrease({required int amount});

  /// Records a base reduction with the exact current timestamp (same
  /// configurable step as increases).
  ///
  /// Precondition enforced in [RequestDecreaseUseCase]: shift must be
  /// initialized AND net increases must exceed net decreases.
  Future<Result<BaseTransactionEntity>> requestDecrease({required int amount});

  /// Records a liquor bottle cost as a debt adjustment.
  ///
  /// This is called by the orders feature when a liquor [OrderItem] is placed.
  /// The [amount] must be the bottle price in COP (positive integer).
  Future<Result<BaseTransactionEntity>> recordLiquorAdjustment({
    required int amount,
    String? note,
  });

  /// Hard-deletes ALL base transactions. Only callable during testing or
  /// shift-reset flows — the use case layer must guard production calls.
  Future<Result<void>> clearAll();
}
