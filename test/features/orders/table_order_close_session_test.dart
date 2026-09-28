import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_base/core/errors/failures.dart';
import 'package:the_base/core/errors/result.dart';
import 'package:the_base/features/orders/domain/repositories/i_order_repository.dart';
import 'package:the_base/features/orders/domain/usecases/watch_table_orders_usecase.dart';
import 'package:the_base/features/orders/presentation/providers/order_providers.dart';
import 'package:the_base/features/tables/domain/entities/table_session_entity.dart';

class _MockOrderRepository implements IOrderRepository {
  int? lastClosedSessionId;
  Result<TableSessionEntity>? closeSessionResult;

  @override
  Future<Result<TableSessionEntity>> closeSession(int sessionId) async {
    lastClosedSessionId = sessionId;
    return closeSessionResult ??
        Ok(
          TableSessionEntity(
            id: sessionId,
            tableNumber: 1,
            openedAt: DateTime.now(),
            closedAt: DateTime.now(),
            status: TableStatus.closed,
            verificationCode: 'FAC-TEST',
          ),
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('TableOrderNotifier.closeSession delegates to orderRepository and returns null on success',
      () async {
    final mockRepo = _MockOrderRepository();
    final container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockRepo),
        watchTableOrdersUseCaseProvider.overrideWithValue(
          WatchTableOrdersUseCase(mockRepo),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(tableOrderProvider(42).notifier);
    final failure = await notifier.closeSession();

    expect(mockRepo.lastClosedSessionId, 42);
    expect(failure, isNull);
  });

  test('TableOrderNotifier.closeSession returns Failure when repository fails',
      () async {
    final mockRepo = _MockOrderRepository()
      ..closeSessionResult = const Err(
        BusinessRuleFailure(
          message: 'No se puede cerrar la mesa porque tiene saldo pendiente.',
        ),
      );

    final container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockRepo),
        watchTableOrdersUseCaseProvider.overrideWithValue(
          WatchTableOrdersUseCase(mockRepo),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(tableOrderProvider(7).notifier);
    final failure = await notifier.closeSession();

    expect(mockRepo.lastClosedSessionId, 7);
    expect(failure, isA<BusinessRuleFailure>());
    expect(failure?.message, contains('saldo pendiente'));
  });
}
