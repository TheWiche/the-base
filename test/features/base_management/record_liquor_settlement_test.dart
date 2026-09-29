import 'package:flutter_test/flutter_test.dart';
import 'package:the_base/core/errors/failures.dart';
import 'package:the_base/core/errors/result.dart';
import 'package:the_base/features/base_management/domain/entities/base_transaction_entity.dart';
import 'package:the_base/features/base_management/domain/entities/wallet_summary.dart';
import 'package:the_base/features/base_management/domain/repositories/i_base_repository.dart';
import 'package:the_base/features/base_management/domain/usecases/record_liquor_settlement_usecase.dart';

class MockBaseRepository implements IBaseRepository {
  bool initialized = true;
  List<BaseTransactionEntity> transactions = [];

  @override
  Future<bool> hasInitialBase() async => initialized;

  @override
  Future<Result<List<BaseTransactionEntity>>> getAllTransactions() async =>
      Ok(transactions);

  @override
  Stream<List<BaseTransactionEntity>> watchTransactions() =>
      Stream.value(transactions);

  @override
  Future<Result<BaseTransactionEntity>> initializeShift({required int amount}) async {
    final tx = BaseTransactionEntity(
      id: 1,
      type: TransactionType.initial,
      amount: amount,
      timestamp: DateTime.now(),
    );
    transactions.add(tx);
    initialized = true;
    return Ok(tx);
  }

  @override
  Future<Result<BaseTransactionEntity>> requestIncrease({required int amount}) async {
    final tx = BaseTransactionEntity(
      id: transactions.length + 1,
      type: TransactionType.increase,
      amount: amount,
      timestamp: DateTime.now(),
    );
    transactions.add(tx);
    return Ok(tx);
  }

  @override
  Future<Result<BaseTransactionEntity>> requestDecrease({required int amount}) async {
    final tx = BaseTransactionEntity(
      id: transactions.length + 1,
      type: TransactionType.decrease,
      amount: amount,
      timestamp: DateTime.now(),
    );
    transactions.add(tx);
    return Ok(tx);
  }

  @override
  Future<Result<BaseTransactionEntity>> recordLiquorAdjustment({
    required int amount,
    String? note,
  }) async {
    final tx = BaseTransactionEntity(
      id: transactions.length + 1,
      type: TransactionType.liquorAdjustment,
      amount: amount,
      timestamp: DateTime.now(),
      note: note,
    );
    transactions.add(tx);
    return Ok(tx);
  }

  @override
  Future<Result<BaseTransactionEntity>> recordLiquorSettlement({
    required int amount,
    String? note,
  }) async {
    final tx = BaseTransactionEntity(
      id: transactions.length + 1,
      type: TransactionType.liquorSettlement,
      amount: amount,
      timestamp: DateTime.now(),
      note: note,
    );
    transactions.add(tx);
    return Ok(tx);
  }

  @override
  Future<Result<void>> clearAll() async {
    transactions.clear();
    initialized = false;
    return const Ok(null);
  }
}

void main() {
  late MockBaseRepository mockRepo;
  late RecordLiquorSettlementUseCase useCase;

  setUp(() {
    mockRepo = MockBaseRepository();
    useCase = RecordLiquorSettlementUseCase(mockRepo);
  });

  group('RecordLiquorSettlementUseCase', () {
    test('fails if amount <= 0', () async {
      final result = await useCase.call(amount: 0);
      expect(result, isA<Err<BaseTransactionEntity>>());
      final err = result as Err<BaseTransactionEntity>;
      expect(err.failure, isA<BusinessRuleFailure>());
      expect(err.failure.message, contains('mayor a cero'));
    });

    test('fails if shift not initialized', () async {
      mockRepo.initialized = false;
      final result = await useCase.call(amount: 50000);
      expect(result, isA<Err<BaseTransactionEntity>>());
      final err = result as Err<BaseTransactionEntity>;
      expect(err.failure.message, contains('iniciar el turno'));
    });

    test('fails if no liquor debt exists', () async {
      mockRepo.transactions = [
        BaseTransactionEntity(
          id: 1,
          type: TransactionType.initial,
          amount: 300000,
          timestamp: DateTime.now(),
        ),
      ];

      final result = await useCase.call(amount: 50000);
      expect(result, isA<Err<BaseTransactionEntity>>());
      final err = result as Err<BaseTransactionEntity>;
      expect(err.failure.message, contains('No tienes deuda pendiente por licor'));
    });

    test('fails if amount exceeds current liquor debt', () async {
      mockRepo.transactions = [
        BaseTransactionEntity(
          id: 1,
          type: TransactionType.initial,
          amount: 300000,
          timestamp: DateTime.now(),
        ),
        BaseTransactionEntity(
          id: 2,
          type: TransactionType.liquorAdjustment,
          amount: 80000,
          timestamp: DateTime.now(),
          note: 'Aguardiente ×1',
        ),
      ];

      final result = await useCase.call(amount: 90000);
      expect(result, isA<Err<BaseTransactionEntity>>());
      final err = result as Err<BaseTransactionEntity>;
      expect(err.failure.message, contains('no puede superar'));
    });

    test('succeeds and records settlement when amount <= liquorDebt', () async {
      mockRepo.transactions = [
        BaseTransactionEntity(
          id: 1,
          type: TransactionType.initial,
          amount: 300000,
          timestamp: DateTime.now(),
        ),
        BaseTransactionEntity(
          id: 2,
          type: TransactionType.liquorAdjustment,
          amount: 80000,
          timestamp: DateTime.now(),
          note: 'Aguardiente ×1',
        ),
        BaseTransactionEntity(
          id: 3,
          type: TransactionType.liquorAdjustment,
          amount: 120000,
          timestamp: DateTime.now(),
          note: 'Ron Medellín ×1',
        ),
      ];

      // Total liquor debt = 200,000. Settle 80,000.
      final result = await useCase.call(
        amount: 80000,
        note: 'Pago Aguardiente en caja',
      );

      expect(result, isA<Ok<BaseTransactionEntity>>());
      final entity = (result as Ok<BaseTransactionEntity>).value;
      expect(entity.type, TransactionType.liquorSettlement);
      expect(entity.amount, 80000);
      expect(entity.note, 'Pago Aguardiente en caja');

      // Check recalculated WalletSummary
      final summary = WalletSummary.fromTransactions(mockRepo.transactions);
      expect(summary.totalLiquorDebt, 120000);
      expect(summary.totalDebt, 300000 + 120000);
      // Available balance is independent of liquor debt and remains initial base
      expect(summary.availableBalance, 300000);
    });

    test('full liquidation brings liquor debt to 0 and adjusts totalDebt cleanly', () async {
      mockRepo.transactions = [
        BaseTransactionEntity(
          id: 1,
          type: TransactionType.initial,
          amount: 300000,
          timestamp: DateTime.now(),
        ),
        BaseTransactionEntity(
          id: 2,
          type: TransactionType.liquorAdjustment,
          amount: 100000,
          timestamp: DateTime.now(),
          note: 'Tequila Don Julio ×1',
        ),
      ];

      final result = await useCase.call(
        amount: 100000,
        note: 'Pago total en caja',
      );

      expect(result, isA<Ok<BaseTransactionEntity>>());

      final summary = WalletSummary.fromTransactions(mockRepo.transactions);
      expect(summary.totalLiquorDebt, 0);
      expect(summary.totalDebt, 300000);
      expect(summary.availableBalance, 300000);
    });
  });
}

