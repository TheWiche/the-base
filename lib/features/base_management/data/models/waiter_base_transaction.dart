import 'package:isar/isar.dart';

// TransactionType is defined in the domain layer.
// Data → Domain import is correct per Clean Architecture dependency rules.
import '../../domain/entities/base_transaction_entity.dart';

part 'waiter_base_transaction.g.dart';

/// Isar collection that persists every financial event touching the waiter's
/// base ledger. Mapped to/from [BaseTransactionEntity] by the repository.
///
/// ── Financial role per type ──────────────────────────────────────────────────
///   [TransactionType.initial]          → sets the $300,000 starting base.
///   [TransactionType.increase]         → adds $100,000 to base AND debt.
///   [TransactionType.liquorAdjustment] → adds bottle cost to DEBT only.
///                                        Does NOT reduce Available Balance.
///
/// [amount] is ALWAYS stored as a positive integer. The [type] field encodes
/// the financial semantics. Never store negative values here.
@collection
class WaiterBaseTransaction {
  Id id = Isar.autoIncrement;

  /// Financial category — drives formula routing in [WalletSummary].
  /// Stored by enum name (string) for human-readability in the Isar inspector
  /// and safety against enum reordering across migrations.
  @enumerated
  late TransactionType type;

  /// Amount in COP. Always positive.
  late int amount;

  /// Exact wall-clock timestamp. Required by business rule for increase auditing.
  /// Indexed for efficient date-range queries (daily report, Cierre).
  @Index()
  late DateTime timestamp;

  /// Optional human note (e.g., "Autorizado por encargado", product name for
  /// liquor adjustments). Never used in financial calculations.
  String? note;
}
