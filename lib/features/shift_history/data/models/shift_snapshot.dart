import 'package:isar/isar.dart';

part 'shift_snapshot.g.dart';

/// Persisted summary of one completed waiter shift.
///
/// Saved atomically BEFORE the daily Isar wipe so the record survives across
/// shifts. All computed values (totalDebt, netProfit, etc.) are pre-calculated
/// at save time — no re-computation required when reading history.
///
/// ── Clearing contract ─────────────────────────────────────────────────────────
/// [CierreRepositoryImpl.finalizeShift] clears every other collection but
/// intentionally leaves [ShiftSnapshot] intact so the history accumulates.
@collection
class ShiftSnapshot {
  Id id = Isar.autoIncrement;

  /// When the shift was finalized (used as the display date and sort key).
  @Index()
  late DateTime snapshotAt;

  // ── Base wallet components ────────────────────────────────────────────────
  late int initialBase;
  late int totalIncreases;
  late int totalDecreases;
  late int totalLiquorDebt;

  // ── Billing components (injected by dashboard enrichment) ─────────────────
  late int verifiedTransfersTotal;
  late int cashPaymentsTotal;
  late int servedStandardItemsTotal;
  late int transferTipsTotal;

  // ── Cierre calculator output ──────────────────────────────────────────────
  late int cashInHand;

  // ── Pre-computed totals (stored to avoid re-derivation) ───────────────────
  late int totalDebt;
  late int availableBalance;
  late int netProfit;
}
