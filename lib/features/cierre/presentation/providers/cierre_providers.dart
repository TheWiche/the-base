import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../data/repositories/cierre_repository_impl.dart';
import '../../domain/entities/cierre_blocker.dart';
import '../../domain/repositories/i_cierre_repository.dart';
import '../../domain/usecases/finalize_shift_usecase.dart';

// ── Dependency injection ───────────────────────────────────────────────────────

final cierreRepositoryProvider = Provider<ICierreRepository>(
  (ref) => CierreRepositoryImpl(),
);

final finalizeShiftUseCaseProvider = Provider<FinalizeShiftUseCase>(
  (ref) => FinalizeShiftUseCase(ref.read(cierreRepositoryProvider)),
);

// ── Derived count providers ────────────────────────────────────────────────────

/// Count of transfer receipts NOT yet legalized by the cashier.
/// Derived from [allTransferReceiptsProvider] — no extra Isar query.
final unlegalizedTransferCountProvider = Provider<int>((ref) {
  return ref.watch(pendingTransfersProvider).length;
});

/// Total COP amount locked in pending legalization.
final unlegalizedTransferTotalProvider = Provider<int>((ref) {
  return ref.watch(pendingTransfersProvider).fold(
        0,
        (sum, r) => sum + r.amountPaid,
      );
});

// ── Cierre Blindado validation ────────────────────────────────────────────────

/// Computes the [CierreValidationResult] by checking all three blocking conditions:
///
///   1. [PendingRadarBlocker]         — items still pending in El Radar
///   2. [OpenTablesBlocker]           — sessions with status open/partiallyPaid
///   3. [UnlegalizedTransfersBlocker] — transfers not confirmed in register
///
/// This is a synchronous [Provider] that combines three reactive sub-providers.
/// Every Isar write that changes any of these conditions triggers an automatic
/// re-evaluation — the Cierre screen stays current with no manual polling.
final cierreValidationProvider = Provider<CierreValidationResult>((ref) {
  final radarCount = ref.watch(pendingRadarCountProvider);
  final activeSessions = ref.watch(activeSessionsProvider).valueOrNull ?? [];
  final unlegalizedCount = ref.watch(unlegalizedTransferCountProvider);
  final unlegalizedTotal = ref.watch(unlegalizedTransferTotalProvider);

  final blockers = <CierreBlocker>[];

  if (radarCount > 0) {
    blockers.add(PendingRadarBlocker(count: radarCount));
  }

  if (activeSessions.isNotEmpty) {
    blockers.add(OpenTablesBlocker(sessions: activeSessions));
  }

  if (unlegalizedCount > 0) {
    blockers.add(UnlegalizedTransfersBlocker(
      count: unlegalizedCount,
      totalPending: unlegalizedTotal,
    ));
  }

  return CierreValidationResult(blockers: blockers);
});
