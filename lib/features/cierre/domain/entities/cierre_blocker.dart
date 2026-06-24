import '../../../tables/domain/entities/table_session_entity.dart';

// ── Sealed blocker hierarchy ───────────────────────────────────────────────────

/// A single condition that prevents the daily closing from proceeding.
///
/// Exhaustively pattern-matched in [CierreScreen] to display a specific,
/// actionable error message for each blocker type.
sealed class CierreBlocker {
  const CierreBlocker();
}

/// El Radar has [count] items still in the pending queue.
/// Resolution: deliver or cancel every pending item from El Radar.
final class PendingRadarBlocker extends CierreBlocker {
  const PendingRadarBlocker({required this.count});

  final int count;
}

/// One or more tables are still open or partially paid.
/// Resolution: close all tables (collect remaining payments or cancel items).
final class OpenTablesBlocker extends CierreBlocker {
  const OpenTablesBlocker({required this.sessions});

  final List<TableSessionEntity> sessions;
}

/// One or more transfer receipts have not been verified in the cash register.
/// Resolution: go to Legalizar Transferencias and confirm each one.
final class UnlegalizedTransfersBlocker extends CierreBlocker {
  const UnlegalizedTransfersBlocker({
    required this.count,
    required this.totalPending,
  });

  /// Number of receipts pending legalization.
  final int count;

  /// Sum of [amountPaid] across all unlegalized transfer receipts (COP).
  final int totalPending;
}

// ── Validation result ─────────────────────────────────────────────────────────

/// The result of running all Cierre Blindado pre-conditions.
///
/// [canClose] is `true` only when [blockers] is empty.
/// The UI disables "Finalizar Jornada" when `!canClose` and renders each
/// blocker as a specific, actionable error card.
final class CierreValidationResult {
  const CierreValidationResult({required this.blockers});

  final List<CierreBlocker> blockers;

  bool get canClose => blockers.isEmpty;
}
