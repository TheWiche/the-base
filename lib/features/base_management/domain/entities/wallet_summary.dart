import 'base_transaction_entity.dart';

/// Computed snapshot of the waiter's financial position for the current shift.
///
/// ── Formulas (business rules — NEVER change without owner approval) ──────────
///
///   Total Debt        = initialBase + totalIncreases − totalDecreases + totalLiquorDebt
///
///   Available Balance = initialBase + totalIncreases − totalDecreases
///                       + verifiedTransfersTotal       ← from billing feature
///                       + cashPaymentsTotal            ← from billing feature
///                       − servedStandardItemsTotal     ← from orders feature
///
///   Net Profit (Tips) = physicalCashInHand − totalDebt + transferTipsTotal
///
/// ── Integration points ───────────────────────────────────────────────────────
/// [verifiedTransfersTotal], [cashPaymentsTotal], [servedStandardItemsTotal],
/// and [transferTipsTotal] default to zero. They are populated by the
/// billing/orders features by calling [copyWith] after fetching from their
/// respective repositories. This design lets the base wallet feature be fully
/// functional in isolation.
///
/// ── Immutability ────────────────────────────────────────────────────────────
/// All fields are final. Use [copyWith] to derive new snapshots.
final class WalletSummary {
  const WalletSummary({
    required this.transactions,
    required this.initialBase,
    required this.totalIncreases,
    required this.totalDecreases,
    required this.totalLiquorDebt,
    this.verifiedTransfersTotal = 0,
    this.cashPaymentsTotal = 0,
    this.servedStandardItemsTotal = 0,
    this.transferTipsTotal = 0,
    this.physicalCashInHand = 0,
  });

  // ── Source data ────────────────────────────────────────────────────────────

  /// All base transactions for the current shift, sorted newest-first.
  final List<BaseTransactionEntity> transactions;

  // ── Components from WaiterBaseTransaction ──────────────────────────────────

  final int initialBase;
  final int totalIncreases;

  /// Sum of all [TransactionType.decrease] amounts (always positive values).
  /// Reduces baseCapital, totalDebt, AND availableBalance.
  final int totalDecreases;

  /// Sum of all [TransactionType.liquorAdjustment] amounts.
  /// These inflate Total Debt but NOT Available Balance.
  final int totalLiquorDebt;

  // ── Components injected by other features ──────────────────────────────────

  /// Sum of [PaymentReceipt.amountPaid] where method == transfer AND
  /// [isLegalizedInCaja] == true.
  /// Populated by the billing feature — defaults to 0 until integrated.
  final int verifiedTransfersTotal;

  /// Sum of (amountPaid − changeGiven) for all [PaymentMethod.cash] receipts.
  /// Cash is counted immediately on receipt — no cashier legalization required.
  /// Populated by the billing feature — defaults to 0 until integrated.
  final int cashPaymentsTotal;

  /// Sum of [OrderItem.lineTotal] where category == standard AND
  /// status == delivered (served to the customer).
  /// Populated by the orders feature — defaults to 0 until integrated.
  final int servedStandardItemsTotal;

  /// Sum of [PaymentReceipt.tipAmount] where method == transfer.
  /// Populated by the billing feature — defaults to 0 until integrated.
  final int transferTipsTotal;

  /// Entered manually by the waiter at Cierre time: total physical cash in hand.
  final int physicalCashInHand;

  // ── Computed properties (formula implementations) ─────────────────────────

  /// initialBase + totalIncreases − totalDecreases — the capital actually committed.
  int get baseCapital => initialBase + totalIncreases - totalDecreases;

  /// FORMULA: Total Debt = Initial Base + Σ(Increases) − Σ(Decreases) + Σ(Liquor Costs)
  int get totalDebt => initialBase + totalIncreases - totalDecreases + totalLiquorDebt;

  /// FORMULA: Available Balance = Initial Base + Σ(Increases) − Σ(Decreases)
  ///                              + Σ(Verified Transfers)
  ///                              + Σ(Cash Payments Net Received)
  ///                              − Σ(Served Standard Items)
  int get availableBalance =>
      initialBase +
      totalIncreases -
      totalDecreases +
      verifiedTransfersTotal +
      cashPaymentsTotal -
      servedStandardItemsTotal;

  /// FORMULA: Net Profit = Physical Cash − Total Debt + Σ(Transfer Tips)
  int get netProfit => physicalCashInHand - totalDebt + transferTipsTotal;

  // ── State helpers ──────────────────────────────────────────────────────────

  /// True once the one-time initial $300,000 base has been created.
  bool get hasInitialBase => initialBase > 0;

  /// The waiter may only request increases after the shift has been initialized.
  bool get canRequestIncrease => hasInitialBase;

  /// The waiter may only decrease if there are net increases to offset
  /// (prevents reducing below the original initial base).
  bool get canRequestDecrease => hasInitialBase && totalIncreases > totalDecreases;

  /// True when the available balance is positive (waiter has funds remaining).
  bool get isSolvent => availableBalance >= 0;

  /// Sorted transaction log (newest first) for display in history list.
  List<BaseTransactionEntity> get sortedTransactions => [
        ...transactions
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      ];

  // ── Factories ──────────────────────────────────────────────────────────────

  factory WalletSummary.empty() => const WalletSummary(
        transactions: [],
        initialBase: 0,
        totalIncreases: 0,
        totalDecreases: 0,
        totalLiquorDebt: 0,
      );

  /// Primary factory: computes the summary from a raw list of domain entities.
  /// Called by [GetWalletSummaryUseCase] after fetching from the repository.
  factory WalletSummary.fromTransactions(
    List<BaseTransactionEntity> transactions,
  ) {
    int initial = 0;
    int increases = 0;
    int decreases = 0;
    int liquorDebt = 0;

    for (final t in transactions) {
      switch (t.type) {
        case TransactionType.initial:
          initial += t.amount;
        case TransactionType.increase:
          increases += t.amount;
        case TransactionType.decrease:
          decreases += t.amount;
        case TransactionType.liquorAdjustment:
          liquorDebt += t.amount;
        case TransactionType.liquorSettlement:
          // Botella completada: reduce la deuda de licor (pass-through).
          liquorDebt -= t.amount;
      }
    }

    return WalletSummary(
      transactions: transactions,
      initialBase: initial,
      totalIncreases: increases,
      totalDecreases: decreases,
      totalLiquorDebt: liquorDebt,
    );
  }

  WalletSummary copyWith({
    List<BaseTransactionEntity>? transactions,
    int? initialBase,
    int? totalIncreases,
    int? totalDecreases,
    int? totalLiquorDebt,
    int? verifiedTransfersTotal,
    int? cashPaymentsTotal,
    int? servedStandardItemsTotal,
    int? transferTipsTotal,
    int? physicalCashInHand,
  }) =>
      WalletSummary(
        transactions: transactions ?? this.transactions,
        initialBase: initialBase ?? this.initialBase,
        totalIncreases: totalIncreases ?? this.totalIncreases,
        totalDecreases: totalDecreases ?? this.totalDecreases,
        totalLiquorDebt: totalLiquorDebt ?? this.totalLiquorDebt,
        verifiedTransfersTotal:
            verifiedTransfersTotal ?? this.verifiedTransfersTotal,
        cashPaymentsTotal: cashPaymentsTotal ?? this.cashPaymentsTotal,
        servedStandardItemsTotal:
            servedStandardItemsTotal ?? this.servedStandardItemsTotal,
        transferTipsTotal: transferTipsTotal ?? this.transferTipsTotal,
        physicalCashInHand: physicalCashInHand ?? this.physicalCashInHand,
      );

  @override
  String toString() =>
      'WalletSummary(balance: $availableBalance, debt: $totalDebt)';
}
