import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/entities/pending_radar_item.dart';
import '../../domain/repositories/i_order_repository.dart';
import '../../domain/usecases/add_order_item_usecase.dart';
import '../../domain/usecases/cancel_order_item_usecase.dart';
import '../../domain/usecases/mark_item_delivered_usecase.dart';
import '../../domain/usecases/open_table_usecase.dart';
import '../../domain/usecases/watch_pending_radar_items_usecase.dart';
import '../../domain/usecases/watch_table_orders_usecase.dart';
import '../../../tables/domain/entities/table_session_entity.dart';

// ── Dependency injection ───────────────────────────────────────────────────────

final orderRepositoryProvider = Provider<IOrderRepository>(
  (ref) => OrderRepositoryImpl(),
);

final openTableUseCaseProvider = Provider<OpenTableUseCase>(
  (ref) => OpenTableUseCase(ref.read(orderRepositoryProvider)),
);

final addOrderItemUseCaseProvider = Provider<AddOrderItemUseCase>(
  (ref) => AddOrderItemUseCase(ref.read(orderRepositoryProvider)),
);

final cancelOrderItemUseCaseProvider = Provider<CancelOrderItemUseCase>(
  (ref) => CancelOrderItemUseCase(ref.read(orderRepositoryProvider)),
);

final markItemDeliveredUseCaseProvider = Provider<MarkItemDeliveredUseCase>(
  (ref) => MarkItemDeliveredUseCase(ref.read(orderRepositoryProvider)),
);

final watchPendingRadarItemsUseCaseProvider =
    Provider<WatchPendingRadarItemsUseCase>(
  (ref) => WatchPendingRadarItemsUseCase(ref.read(orderRepositoryProvider)),
);

final watchTableOrdersUseCaseProvider = Provider<WatchTableOrdersUseCase>(
  (ref) => WatchTableOrdersUseCase(ref.read(orderRepositoryProvider)),
);

// ── Active sessions (tables grid) ─────────────────────────────────────────────

final activeSessionsProvider = StreamProvider<List<TableSessionEntity>>((ref) {
  return ref.read(orderRepositoryProvider).watchActiveSessions();
});

// ── Table order notifier (per-session) ────────────────────────────────────────

/// Manages item list and actions for a single active table session.
/// Scoped per [sessionId] using the `.family` modifier.
///
/// `autoDispose`: without it, every table ever watched in the app session
/// (e.g. from a card in the Mesas grid) would keep its Isar stream
/// subscription alive forever, even after the card scrolls off-screen or the
/// table closes — a real leak once the grid started watching this provider
/// per card for live totals. autoDispose lets Riverpod tear it down the
/// moment nothing watches it, and cheaply re-subscribe if watched again.
class TableOrderNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<OrderItemEntity>, int> {
  int get sessionId => arg;

  @override
  Future<List<OrderItemEntity>> build(int arg) async {
    final useCase = ref.read(watchTableOrdersUseCaseProvider);
    final sub = useCase.call(arg).listen(
          (items) {
            if (!state.isLoading) state = AsyncData(items);
          },
          onError: (Object error, StackTrace st) {
            state = AsyncError(error, st);
          },
        );
    ref.onDispose(sub.cancel);
    return useCase.call(arg).first;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<Failure?> addItem(AddItemParams params) async {
    final result =
        await ref.read(addOrderItemUseCaseProvider).call(params);
    return _failure(result);
  }

  /// Re-adds a batch of items as new pending lines ("repetir ronda" / "repetir
  /// ítem"). Written atomically by the repository.
  Future<Failure?> repeatItems(List<AddItemParams> items) async {
    final result =
        await ref.read(orderRepositoryProvider).repeatItems(sessionId, items);
    return _failure(result);
  }

  Future<Failure?> cancelItem(int itemId) async {
    final result =
        await ref.read(cancelOrderItemUseCaseProvider).call(itemId);
    return _failure(result);
  }

  /// Deshace un cancelItem reciente — vuelve el ítem a pendiente.
  Future<Failure?> uncancelItem(int itemId) async {
    final result = await ref.read(orderRepositoryProvider).uncancelItem(itemId);
    return _failure(result);
  }

  Future<Failure?> markDelivered(int itemId) async {
    final result =
        await ref.read(markItemDeliveredUseCaseProvider).call(itemId);
    return _failure(result);
  }

  Future<Failure?> renameApodo(String? newApodo) async {
    final result = await ref
        .read(orderRepositoryProvider)
        .renameApodo(sessionId, newApodo);
    return _failure(result);
  }

  Future<Failure?> deleteItem(int itemId) async {
    final result =
        await ref.read(orderRepositoryProvider).deleteItem(itemId);
    return _failure(result);
  }

  /// Completa una botella de licor (pass-through): baja la deuda de licor y la
  /// saca de la cuenta, sin registrar efectivo.
  Future<Failure?> settleLiquor(int itemId) async {
    final result =
        await ref.read(orderRepositoryProvider).settleLiquorItem(itemId);
    return _failure(result);
  }

  Future<Failure?> clearCancelledItems() async {
    final result = await ref
        .read(orderRepositoryProvider)
        .clearCancelledItems(sessionId);
    return _failure(result);
  }

  Failure? _failure<T>(Result<T> result) => switch (result) {
        Ok() => null,
        Err(:final failure) => failure,
      };
}

final tableOrderProvider = AsyncNotifierProvider.autoDispose
    .family<TableOrderNotifier, List<OrderItemEntity>, int>(
  TableOrderNotifier.new,
);

// ── Botellas de licor no pagadas (para "Pagar Botella" en Billetera) ──────────

final unpaidLiquorItemsProvider = StreamProvider<List<OrderItemEntity>>((ref) {
  return ref.watch(orderRepositoryProvider).watchUnpaidLiquorItems();
});

/// Acción para saldar una botella desde cualquier pantalla (Billetera).
final settleLiquorActionProvider =
    Provider<Future<Failure?> Function(int itemId)>((ref) {
  final repo = ref.read(orderRepositoryProvider);
  return (itemId) async {
    final result = await repo.settleLiquorItem(itemId);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => failure,
    };
  };
});

// ── Pending radar items (all tables) ──────────────────────────────────────────

final pendingRadarItemsProvider =
    StreamProvider<List<PendingRadarItem>>((ref) {
  return ref.read(watchPendingRadarItemsUseCaseProvider).call();
});

/// Convenience: total count for the radar badge on the bottom nav.
final pendingRadarCountProvider = Provider<int>((ref) {
  return ref.watch(pendingRadarItemsProvider).maybeWhen(
        data: (items) => items.length,
        orElse: () => 0,
      );
});

/// Derives a single [TableSessionEntity] by [sessionId] from the active sessions stream.
/// Returns null while loading, or if the session is not found / already closed.
final tableSessionByIdProvider =
    Provider.family.autoDispose<TableSessionEntity?, int>((ref, sessionId) {
  return ref.watch(activeSessionsProvider).maybeWhen(
        data: (sessions) {
          final filtered = sessions.where((s) => s.id == sessionId);
          return filtered.isEmpty ? null : filtered.first;
        },
        orElse: () => null,
      );
});

/// One-shot fetch of any session by ID (active OR closed).
final sessionByIdProvider =
    FutureProvider.family.autoDispose<TableSessionEntity?, int>(
  (ref, sessionId) async {
    final result =
        await ref.read(orderRepositoryProvider).getSession(sessionId);
    return switch (result) {
      Ok(:final value) => value,
      Err() => null,
    };
  },
);

/// All closed sessions, newest-first. Re-fetched on each mount (autoDispose).
final closedSessionsProvider =
    FutureProvider.autoDispose<List<TableSessionEntity>>(
  (ref) async {
    final result =
        await ref.read(orderRepositoryProvider).getClosedSessions();
    return switch (result) {
      Ok(:final value) => value,
      Err() => [],
    };
  },
);
