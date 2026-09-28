import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/domain/entities/pending_radar_item.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../orders/domain/usecases/mark_item_delivered_usecase.dart';
import '../../domain/entities/radar_bar_batch.dart';

// ── Modos de visualización de El Radar ────────────────────────────────────────

enum RadarViewMode {
  /// Orden de llegada cronológico con tiempo transcurrido individual.
  cronologico,

  /// Agrupado por mesa/apodo en formato comanda de papel (tiquete).
  mesas,

  /// Consolidado por producto idéntico para agilizar pedidos en barra.
  barra,
}

final radarViewModeProvider =
    StateProvider<RadarViewMode>((ref) => RadarViewMode.barra);

// ── Clock ticker for live elapsed-time display ────────────────────────────────
//
// Emits DateTime.now() every 30 seconds. Radar widgets watch this provider
// to trigger periodic rebuilds — keeping elapsed-time labels accurate.
// The autoDispose modifier stops the timer when the radar screen is not visible.

final radarClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  while (true) {
    yield DateTime.now();
    await Future<void>.delayed(const Duration(seconds: 30));
  }
});

// ── Computed providers para cada vista ─────────────────────────────────────────

/// Derives [RadarTableGroup]s from the flat pending-items stream (Modo Por Mesas).
final radarGroupedProvider = Provider.autoDispose<List<RadarTableGroup>>((ref) {
  return ref.watch(pendingRadarItemsProvider).maybeWhen(
        data: (items) => items.toTableGroups(),
        orElse: () => [],
      );
});

/// Derives [RadarBarBatch]es consolidando por producto y variantes (Modo Barra).
final radarBarBatchesProvider = Provider.autoDispose<List<RadarBarBatch>>((ref) {
  return ref.watch(pendingRadarItemsProvider).maybeWhen(
        data: (items) => items.toBarBatches(),
        orElse: () => [],
      );
});

/// Flat list of items sorted chronologically (Modo Cronológico).
final radarChronologicalProvider =
    Provider.autoDispose<List<PendingRadarItem>>((ref) {
  return ref.watch(pendingRadarItemsProvider).maybeWhen(
        data: (items) => items,
        orElse: () => [],
      );
});

// ── Deliver action providers ───────────────────────────────────────────────────

/// Exposes the [MarkItemDeliveredUseCase] as a callable that returns [Failure?].
/// Used by single-item delivery actions.
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

/// Entrega un lote de múltiples ítems a la vez (Modo Barra o despacho múltiple).
final deliverItemsBatchProvider =
    Provider.autoDispose<Future<Failure?> Function(List<int> itemIds)>((ref) {
  final repo = ref.read(orderRepositoryProvider);
  return (itemIds) async {
    final result = await repo.markItemsDelivered(itemIds);
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
