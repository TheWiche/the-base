import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/domain/entities/pending_radar_item.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../orders/domain/usecases/mark_item_delivered_usecase.dart';

// ── Radar view mode ────────────────────────────────────────────────────────────

enum RadarViewMode {
  /// Flat list sorted by orderedAt ASC (oldest first).
  chronological,

  /// Items grouped by table, each group sorted by orderedAt ASC.
  /// Groups themselves ordered by oldest item first (most urgent table at top).
  grouped,
}

// ── View mode state ────────────────────────────────────────────────────────────

final radarViewModeProvider = StateProvider<RadarViewMode>(
  (ref) => RadarViewMode.grouped,
);

// ── Clock ticker for live elapsed-time display ────────────────────────────────
//
// Emits DateTime.now() every 30 seconds. RadarItemTile watches this provider
// to trigger periodic rebuilds — keeping elapsed-time labels accurate.
// The autoDispose modifier stops the timer when the radar screen is not visible.

final radarClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  while (true) {
    yield DateTime.now();
    await Future<void>.delayed(const Duration(seconds: 30));
  }
});

// ── Grouped view computed provider ────────────────────────────────────────────

/// Derives [RadarTableGroup]s from the flat pending-items stream.
/// Only active when [radarViewModeProvider] is [RadarViewMode.grouped].
final radarGroupedProvider = Provider.autoDispose<List<RadarTableGroup>>((ref) {
  return ref.watch(pendingRadarItemsProvider).maybeWhen(
        data: (items) => items.toTableGroups(),
        orElse: () => [],
      );
});

// ── Deliver action provider ────────────────────────────────────────────────────

/// Exposes the [MarkItemDeliveredUseCase] as a callable that returns [Failure?].
/// Used by both chronological and grouped tile widgets.
final deliverItemProvider =
    Provider.autoDispose<Future<Failure?> Function(int itemId)>((ref) {
  final useCase = ref.read(markItemDeliveredUseCaseProvider);
  return (itemId) async {
    final result = await useCase.call(itemId);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => failure,
    };
  };
});

/// Entrega TODOS los pendientes de una mesa a la vez (botón "Entregar todo").
final deliverTableProvider =
    Provider.autoDispose<Future<Failure?> Function(int sessionId)>((ref) {
  final repo = ref.read(orderRepositoryProvider);
  return (sessionId) async {
    final result = await repo.markTableDelivered(sessionId);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => failure,
    };
  };
});

// ── Urgency color extension (re-exported for widgets) ────────────────────────

extension RadarUrgencyUI on RadarUrgency {
  /// Format "Hace X min" or "Ahora" for display.
  static String formatElapsed(Duration elapsed) {
    final minutes = elapsed.inMinutes;
    if (minutes < 1) return 'Ahora';
    return 'Hace $minutes min';
  }
}
