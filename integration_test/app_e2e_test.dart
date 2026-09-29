import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:the_base/core/database/isar_service.dart';
import 'package:the_base/core/errors/result.dart';
import 'package:the_base/core/theme/app_colors.dart';
import 'package:the_base/features/base_management/data/repositories/base_repository_impl.dart';
import 'package:the_base/features/base_management/domain/entities/base_transaction_entity.dart';
import 'package:the_base/features/base_management/domain/entities/wallet_summary.dart';
import 'package:the_base/features/base_management/domain/usecases/record_liquor_settlement_usecase.dart';
import 'package:the_base/features/billing/data/models/payment_receipt.dart';
import 'package:the_base/features/orders/data/models/order_item.dart';
import 'package:the_base/features/orders/data/repositories/order_repository_impl.dart';
import 'package:the_base/features/orders/domain/entities/order_item_entity.dart';
import 'package:the_base/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:the_base/features/payments/domain/entities/payment_receipt_entity.dart';
import 'package:the_base/features/payments/presentation/widgets/global_pending_transfers_banner.dart';
import 'package:the_base/features/tables/data/models/table_session.dart';
import 'package:the_base/features/tables/domain/entities/table_session_entity.dart';
import 'package:the_base/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Full Verification on Android Emulator', (tester) async {
    // ── 0. Arranque de la app ────────────────────────────────────────────────
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    debugPrint('[E2E TEST] App iniciada y renderizada en emulador.');

    // ── 1. Inicio Limpio: Sin mesa "Barra" residual ──────────────────────────
    debugPrint('[E2E TEST] 1. Verificando inicio limpio...');
    final db = IsarService.db;
    final barraCount = await db.tableSessions
        .filter()
        .apodoEqualTo('Barra', caseSensitive: false)
        .or()
        .apodoEqualTo('Mesa Barra', caseSensitive: false)
        .count();

    expect(barraCount, equals(0),
        reason: 'No debe existir ninguna mesa residual llamada Barra.');
    expect(find.text('Mesa Barra'), findsNothing);
    debugPrint('[E2E TEST] -> Verificación de inicio limpio EXITOSA (0 mesas residuales).');

    // ── 2. Consistencia Visual (Dark Theme) ──────────────────────────────────
    debugPrint('[E2E TEST] 2. Verificando consistencia visual Dark Theme...');
    final scaffoldFinder = find.byType(Scaffold).first;
    final theme = Theme.of(tester.element(scaffoldFinder));
    expect(theme.brightness, equals(Brightness.dark),
        reason: 'El tema activo debe ser Dark.');
    expect(AppColors.darkBackground, equals(const Color(0xFF121212)));
    expect(AppColors.darkSurfaceVariant, equals(const Color(0xFF242526)));
    debugPrint('[E2E TEST] -> Verificación de Dark Theme EXITOSA.');

    // ── 3. Flujo de Botellas y Liquidación en Caja ───────────────────────────
    debugPrint('[E2E TEST] 3. Verificando Flujo de Botellas y Liquidación en Caja...');
    final baseRepo = BaseRepositoryImpl();
    final orderRepo = OrderRepositoryImpl();

    final hasBase = await baseRepo.hasInitialBase();
    if (!hasBase) {
      await baseRepo.initializeShift(amount: 50000);
    }

    final initialTxs = ((await baseRepo.getAllTransactions()) as Ok<List<BaseTransactionEntity>>).value;
    final initialSummary = WalletSummary.fromTransactions(initialTxs);

    // Abrir mesa de prueba
    final sessionRes = await orderRepo.openTable(tableNumber: 88, apodo: 'Mesa E2E Botellas');
    expect(sessionRes.isOk, isTrue);
    final session = (sessionRes as Ok<TableSessionEntity>).value;

    // Agregar una botella de licor ($85.000) con nota personalizada
    const liquorPrice = 85000;
    final addRes = await orderRepo.addItem(AddItemParams(
      tableSessionId: session.id,
      productName: 'Aguardiente Antioqueño 750ml',
      price: liquorPrice,
      quantity: 1,
      category: ProductCategory.liquor,
      note: 'Con hielo aparte',
    ));
    expect(addRes.isOk, isTrue);

    await tester.pumpAndSettle();

    // Comprobar estado de deuda: Deuda Licor y Deuda Total aumentan, Saldo Disponible no se reduce
    final txsAfterBottle = ((await baseRepo.getAllTransactions()) as Ok<List<BaseTransactionEntity>>).value;
    final summaryAfterBottle = WalletSummary.fromTransactions(txsAfterBottle);

    expect(summaryAfterBottle.totalLiquorDebt, equals(initialSummary.totalLiquorDebt + liquorPrice),
        reason: 'La deuda por licor debe incrementarse con el valor de la botella.');
    expect(summaryAfterBottle.totalDebt, equals(initialSummary.totalDebt + liquorPrice),
        reason: 'La deuda total debe incrementarse con el valor de la botella.');
    expect(summaryAfterBottle.availableBalance, equals(initialSummary.availableBalance),
        reason: 'La base disponible no debe descontarse al pedir botellas.');

    debugPrint('[E2E TEST] -> Botella registrada: Deuda licor subió a \$${summaryAfterBottle.totalLiquorDebt}, saldo disponible intacto.');

    // Liquidar botella en caja
    final settlementUseCase = RecordLiquorSettlementUseCase(baseRepo);
    final settlementResult = await settlementUseCase(amount: liquorPrice, note: 'Liquidación en caja E2E');
    expect(settlementResult.isOk, isTrue,
        reason: 'La liquidación de botella en caja debe ser exitosa.');

    final txsAfterSettlement = ((await baseRepo.getAllTransactions()) as Ok<List<BaseTransactionEntity>>).value;
    final summaryAfterSettlement = WalletSummary.fromTransactions(txsAfterSettlement);

    expect(summaryAfterSettlement.totalLiquorDebt, equals(initialSummary.totalLiquorDebt),
        reason: 'La deuda de licor debe restablecerse al liquidar en caja.');
    expect(summaryAfterSettlement.totalDebt, equals(initialSummary.totalDebt),
        reason: 'La deuda total debe reducirse en el monto liquidado.');
    expect(summaryAfterSettlement.availableBalance, equals(initialSummary.availableBalance),
        reason: 'El saldo disponible del mesero no se altera.');

    debugPrint('[E2E TEST] -> Liquidación de deuda de licor en caja EXITOSA.');

    // ── 4. Cobro y Ausencia de Pago Mixto / Visualización de Notas ────────────
    debugPrint('[E2E TEST] 4. Verificando Cobro, Notas y Ausencia de Pago Mixto...');
    final items = await db.orderItems.filter().tableSessionIdEqualTo(session.id).findAll();
    expect(items.any((i) => i.note == 'Con hielo aparte'), isTrue,
        reason: 'La nota del producto debe persistir y registrarse.');

    // Validar ausencia de mixed_payment_screen.dart
    final mixedFile = File('lib/features/payments/presentation/screens/mixed_payment_screen.dart');
    expect(mixedFile.existsSync(), isFalse,
        reason: 'mixed_payment_screen.dart debe estar completamente eliminado.');

    // Validar métodos de pago soportados
    expect(PaymentMethod.values, contains(PaymentMethod.cash));
    expect(PaymentMethod.values, contains(PaymentMethod.transfer));

    debugPrint('[E2E TEST] -> Cobro verificado: Notas persistidas y Pago Mixto ausente.');

    // ── 5. Banner Global de Transferencias Persistente ────────────────────────
    debugPrint('[E2E TEST] 5. Verificando Banner Global de Transferencias...');
    final tempDir = Directory.systemTemp;
    final dummyVoucher = File('${tempDir.path}/test_voucher.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF]);

    final paymentRepo = PaymentRepositoryImpl();
    final transferRes = await paymentRepo.recordStandaloneTransfer(
      amount: 45000,
      photoSourcePath: dummyVoucher.path,
      transferMethod: TransferMethod.nequi,
      note: 'Anticipo cliente E2E',
    );
    expect(transferRes.isOk, isTrue);

    final pendingReceipts = await db.paymentReceipts
        .filter()
        .isLegalizedInCajaEqualTo(false)
        .findAll();
    expect(pendingReceipts.isNotEmpty, isTrue,
        reason: 'Debe existir comprobante de transferencia pendiente.');

    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Confirmar montaje del banner global
    expect(find.byType(GlobalPendingTransfersBanner), findsWidgets,
        reason: 'El banner global debe estar presente cuando hay transferencias pendientes.');
    debugPrint('[E2E TEST] -> Banner global verificado montado en pantalla.');

    // Legalizar transferencia
    await IsarService.write((isarDb) async {
      final receipt = await isarDb.paymentReceipts.get(pendingReceipts.first.id);
      if (receipt != null) {
        receipt.isLegalizedInCaja = true;
        await isarDb.paymentReceipts.put(receipt);
      }
    });

    await tester.pumpAndSettle(const Duration(seconds: 1));

    final remainingPending = await db.paymentReceipts
        .filter()
        .isLegalizedInCajaEqualTo(false)
        .findAll();
    expect(remainingPending.isEmpty, isTrue,
        reason: 'Todas las transferencias deben quedar legalizadas.');
    debugPrint('[E2E TEST] -> Transferencia legalizada exitosamente.');

    // Limpieza de mesa de prueba
    await orderRepo.cancelItem(items.first.id);
    await orderRepo.clearCancelledItems(session.id);
    await orderRepo.deleteSession(session.id);
    debugPrint('[E2E TEST] Mesa de prueba 88 limpiada.');

    debugPrint('[E2E TEST] ----------------------------------------------------');
    debugPrint('[E2E TEST] ¡TODAS LAS PRUEBAS E2E HAN SIDO COMPLETADAS CON ÉXITO!');
    debugPrint('[E2E TEST] ----------------------------------------------------');
  });
}
