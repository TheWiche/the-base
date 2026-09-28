import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/financial_constants.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/gallery/gallery_saver.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../billing/data/models/payment_receipt.dart';
import '../../../orders/data/models/order_item.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../tables/data/models/table_session.dart';
import '../../../tables/domain/entities/table_session_entity.dart';
import '../../domain/entities/payment_receipt_entity.dart';
import '../../domain/repositories/i_payment_repository.dart';

final class PaymentRepositoryImpl implements IPaymentRepository {
  @override
  Future<Result<PaymentReceiptEntity>> recordPayment(
    RecordPaymentParams params,
  ) async {
    try {
      final now = DateTime.now();

      // ── Step 1: Copy photo(s) to Bonanza_Transferencias (outside Isar txn) ─
      String? finalPhotoPath;
      if (params.photoSourcePath != null) {
        finalPhotoPath = await _copyToTransferDir(
          sourcePath: params.photoSourcePath!,
          sessionId: params.tableSessionId,
          paidAt: now,
        );
        await GallerySaver.saveImage(
          sourcePath: params.photoSourcePath!,
          fileName: 'transfer_${params.tableSessionId}_'
              '${now.millisecondsSinceEpoch}.jpg',
        );
      }

      String? finalMixedPhotoPath;
      if (params.isMixed && params.mixedPhotoSourcePath != null) {
        finalMixedPhotoPath = await _copyToTransferDir(
          sourcePath: params.mixedPhotoSourcePath!,
          sessionId: params.tableSessionId,
          paidAt: now,
        );
        await GallerySaver.saveImage(
          sourcePath: params.mixedPhotoSourcePath!,
          fileName: 'transfer_mixed_${params.tableSessionId}_'
              '${now.millisecondsSinceEpoch}.jpg',
        );
      }

      // ── Step 2: Atomic Isar write ─────────────────────────────────────────
      late PaymentReceiptEntity entity;

      await IsarService.write((db) async {
        final session = await db.tableSessions.get(params.tableSessionId);
        if (session == null) {
          throw StateError(
            'TableSession ${params.tableSessionId} not found — '
            'cannot attach PaymentReceipt.',
          );
        }

        int primaryReceiptId = 0;

        // 2a. Build and persist receipts (single or mixed) ───────────────────
        if (params.isMixed) {
          final groupId = 'mixed_${params.tableSessionId}_${now.millisecondsSinceEpoch}';

          final cashReceipt = PaymentReceipt()
            ..tableSessionId = params.tableSessionId
            ..amountPaid = params.cashAmount ?? 0
            ..changeGiven = params.changeGiven
            ..tipAmount = 0
            ..paymentMethod = PaymentMethod.cash
            ..isLegalizedInCaja = true
            ..isGeneralAdvance = params.isGeneralAdvance
            ..transactionGroupId = groupId
            ..note = 'Cobro mixto (Efectivo)'
            ..paidAt = now;

          final cashId = await db.paymentReceipts.put(cashReceipt);
          cashReceipt.id = cashId;
          session.payments.add(cashReceipt);

          final transferReceipt = PaymentReceipt()
            ..tableSessionId = params.tableSessionId
            ..amountPaid = params.transferAmount ?? 0
            ..changeGiven = 0
            ..tipAmount = params.tipAmount
            ..paymentMethod = PaymentMethod.transfer
            ..transferMethodIndex = params.mixedTransferMethod?.index
            ..photoPath = finalMixedPhotoPath
            ..isLegalizedInCaja = false
            ..verificationCode = _generateCode(
                '${params.tableSessionId}:${params.transferAmount}:${now.millisecondsSinceEpoch}')
            ..isGeneralAdvance = params.isGeneralAdvance
            ..transactionGroupId = groupId
            ..note = 'Cobro mixto (Transferencia)'
            ..paidAt = now;

          final transferId = await db.paymentReceipts.put(transferReceipt);
          transferReceipt.id = transferId;
          session.payments.add(transferReceipt);

          primaryReceiptId = transferId;
          entity = _mapToEntity(transferReceipt);
        } else {
          final receiptModel = PaymentReceipt()
            ..tableSessionId = params.tableSessionId
            ..amountPaid = params.amountPaid
            ..changeGiven = params.changeGiven
            ..tipAmount = params.tipAmount
            ..paymentMethod = params.paymentMethod
            ..transferMethodIndex = params.transferMethod?.index
            ..photoPath = finalPhotoPath
            ..isLegalizedInCaja = params.paymentMethod == PaymentMethod.cash
            ..verificationCode = params.isTransfer
                ? _generateCode(
                    '${params.tableSessionId}:${params.amountPaid}:${now.millisecondsSinceEpoch}',
                  )
                : null
            ..isGeneralAdvance = params.isGeneralAdvance
            ..note = params.note
            ..paidAt = now;

          final receiptId = await db.paymentReceipts.put(receiptModel);
          receiptModel.id = receiptId;
          session.payments.add(receiptModel);
          primaryReceiptId = receiptId;
          entity = _mapToEntity(receiptModel);
        }

        await session.payments.save();

        // 2b. If selective item billing, mark items (or units) as paid ───────
        if (!params.isGeneralAdvance && params.selectedItemIds.isNotEmpty) {
          final selectedModels =
              (await db.orderItems.getAll(params.selectedItemIds))
                  .whereType<OrderItem>()
                  .toList();

          final splitItems = <OrderItem>[];
          for (final item in selectedModels) {
            if (item.isPaid) continue; // idempotent guard

            final requested =
                params.selectedQuantities[item.id] ?? item.quantity;
            final payUnits = requested.clamp(1, item.quantity);

            if (payUnits >= item.quantity) {
              item.isPaid = true;
              item.paymentReceiptId = primaryReceiptId;
              if (item.status == OrderItemStatus.pending) {
                item.status = OrderItemStatus.delivered;
                item.deliveredAt = now;
              }
            } else {
              item.quantity -= payUnits;
              splitItems.add(
                OrderItem()
                  ..tableSessionId = item.tableSessionId
                  ..productName = item.productName
                  ..productCatalogId = item.productCatalogId
                  ..price = item.price
                  ..quantity = payUnits
                  ..category = item.category
                  ..orderedAt = item.orderedAt
                  ..deliveredAt = now
                  ..status = OrderItemStatus.delivered
                  ..isPaid = true
                  ..paymentReceiptId = primaryReceiptId
                  ..note = item.note,
              );
            }
          }
          if (selectedModels.isNotEmpty) {
            await db.orderItems.putAll(selectedModels);
          }
          for (final part in splitItems) {
            part.id = await db.orderItems.put(part);
            part.tableSession.value = session;
            await part.tableSession.save();
          }
        }

        // 2c. Recompute session status and check full settlement ──────────────
        await session.orderItems.load();
        final allItemIds = session.orderItems.map((i) => i.id).toList();
        final allItems = (await db.orderItems.getAll(allItemIds))
            .whereType<OrderItem>()
            .where((i) => i.status != OrderItemStatus.cancelled)
            .toList();

        final totalBill =
            allItems.fold<int>(0, (sum, i) => sum + i.price * i.quantity);

        await session.payments.load();
        final totalPaid = session.payments.fold<int>(
          0,
          (sum, p) => sum + (p.amountPaid - p.changeGiven),
        );

        final isFullyCovered =
            allItems.isNotEmpty && totalPaid >= totalBill && totalBill > 0;
        final allItemsPaid =
            allItems.isNotEmpty && allItems.every((i) => i.isPaid);

        if (isFullyCovered || allItemsPaid) {
          // If covered by general advances, ensure all active lines are stamped paid.
          for (final item in allItems) {
            if (!item.isPaid) {
              item.isPaid = true;
              if (item.status == OrderItemStatus.pending) {
                item.status = OrderItemStatus.delivered;
                item.deliveredAt = now;
              }
            }
          }
          await db.orderItems.putAll(allItems);

          session.status = TableStatus.closed;
          session.closedAt = now;
          session.verificationCode = _generateCode(
            '${params.tableSessionId}:$totalBill:${now.millisecondsSinceEpoch}',
          );
        } else {
          session.status = TableStatus.partiallyPaid;
        }
        await db.tableSessions.put(session);
      });

      return ok(entity);
    } on StateError catch (e) {
      return err(NotFoundFailure(message: e.message));
    } catch (e, st) {
      // Clean up the photo copy if the Isar write failed.
      // ignore: avoid_catches_without_on_clauses
      return err(
        DatabaseFailure(
          message: 'Error al registrar el pago: $e',
          stackTrace: st,
        ),
      );
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Copies the temp camera file to the device's Bonanza_Transferencias folder.
  ///
  /// Uses app-specific external storage on Android (no special permissions
  /// required on Android 10+) and app documents on iOS.
  /// The directory is visible in Android file managers for easy bulk deletion.
  Future<String> _copyToTransferDir({
    required String sourcePath,
    required int sessionId,
    required DateTime paidAt,
  }) async {
    final dir = await _getBonanzaTransferDir();
    final filename =
        'transfer_${sessionId}_${paidAt.millisecondsSinceEpoch}.jpg';
    final destPath = '${dir.path}/$filename';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<Directory> _getBonanzaTransferDir() async {
    final Directory base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final dir = Directory('${base.path}/Bonanza_Transferencias');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<Result<PaymentReceiptEntity>> recordStandaloneTransfer({
    required int amount,
    required String photoSourcePath,
    required TransferMethod transferMethod,
    int tipAmount = 0,
    String? note,
  }) async {
    try {
      final now = DateTime.now();
      final dir = await _getBonanzaTransferDir();
      final filename = 'suelta_${now.millisecondsSinceEpoch}.jpg';
      final destPath = '${dir.path}/$filename';
      await File(photoSourcePath).copy(destPath);

      final seed = 'standalone|0|$amount|${now.toIso8601String()}';
      final verificationCode = _generateCode(seed);

      final receipt = PaymentReceipt()
        ..tableSessionId = 0
        ..amountPaid = amount
        ..changeGiven = 0
        ..tipAmount = tipAmount
        ..paymentMethod = PaymentMethod.transfer
        ..transferMethodIndex = transferMethod.index
        ..photoPath = destPath
        ..isLegalizedInCaja = false
        ..paidAt = now
        ..verificationCode = verificationCode
        ..isGeneralAdvance = true
        ..note = note ?? 'Transferencia independiente / suelta';

      final db = IsarService.db;
      await db.writeTxn(() async {
        await db.paymentReceipts.put(receipt);
      });

      return Ok(_mapToEntity(receipt));
    } on Exception catch (e, st) {
      return Err(DatabaseFailure(
        message: 'Error registrando transferencia suelta: $e',
        stackTrace: st,
      ));
    }
  }

  /// Derives an 8-digit numeric verification code from a SHA-256 of [seed].
  ///
  /// Extracts the first [FinancialConstants.verificationCodeLength] decimal
  /// digit characters from the 64-char hex digest. Pads with '0' if the
  /// digest has fewer than 8 digit characters (astronomically unlikely with
  /// SHA-256).
  String _generateCode(String seed) {
    final digest = sha256.convert(utf8.encode(seed)).toString();
    final digits = digest.codeUnits
        .where((c) => c >= 48 && c <= 57)
        .map(String.fromCharCode)
        .join()
        .padRight(FinancialConstants.verificationCodeLength, '0');
    return digits.substring(0, FinancialConstants.verificationCodeLength);
  }

  PaymentReceiptEntity _mapToEntity(PaymentReceipt m) => PaymentReceiptEntity(
        id: m.id,
        tableSessionId: m.tableSessionId,
        amountPaid: m.amountPaid,
        changeGiven: m.changeGiven,
        tipAmount: m.tipAmount,
        paymentMethod: m.paymentMethod,
        transferMethod: m.transferMethodIndex != null
            ? TransferMethod.values[m.transferMethodIndex!]
            : null,
        photoPath: m.photoPath,
        isLegalizedInCaja: m.isLegalizedInCaja,
        verificationCode: m.verificationCode,
        isGeneralAdvance: m.isGeneralAdvance,
        transactionGroupId: m.transactionGroupId,
        note: m.note,
        paidAt: m.paidAt,
      );
}

// ── Convenience extension used only in this file ──────────────────────────────

extension _ParamsX on RecordPaymentParams {
  bool get isTransfer => paymentMethod == PaymentMethod.transfer;
}
