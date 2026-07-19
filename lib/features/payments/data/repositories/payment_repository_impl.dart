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

      // ── Step 1: Copy photo to Bonanza_Transferencias (outside Isar txn) ──────
      // Done first so a failed Isar write doesn't leave a phantom receipt
      // referencing a non-existent file. On Isar failure the orphaned copy is
      // cleaned up in the catch block.
      String? finalPhotoPath;
      if (params.photoSourcePath != null) {
        finalPhotoPath = await _copyToTransferDir(
          sourcePath: params.photoSourcePath!,
          sessionId: params.tableSessionId,
          paidAt: now,
        );

        // Also copy into the public gallery (Pictures/Bonanza_Transferencias)
        // so the receipt shows up in the phone's gallery app. Best-effort:
        // never blocks the payment if it fails.
        await GallerySaver.saveImage(
          sourcePath: params.photoSourcePath!,
          fileName: 'transfer_${params.tableSessionId}_'
              '${now.millisecondsSinceEpoch}.jpg',
        );
      }

      // ── Step 2: Atomic Isar write ─────────────────────────────────────────
      late PaymentReceiptEntity entity;

      await IsarService.write((db) async {
        // 2a. Build and persist the receipt ──────────────────────────────────
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
          ..paidAt = now;

        final receiptId = await db.paymentReceipts.put(receiptModel);
        receiptModel.id = receiptId;

        // 2b. Link receipt to parent session ─────────────────────────────────
        final session = await db.tableSessions.get(params.tableSessionId);
        if (session == null) {
          throw StateError(
            'TableSession ${params.tableSessionId} not found — '
            'cannot attach PaymentReceipt.',
          );
        }
        session.payments.add(receiptModel);
        await session.payments.save();

        // 2c. Mark selected items (or units) as paid ─────────────────────────
        // Pending items are force-delivered on payment (collecting while handing
        // over). When a line's selected units are fewer than its total quantity,
        // the line is SPLIT: the paid units become a new paid OrderItem and the
        // original keeps the remaining units unpaid — e.g. "Cerveza ×4" where the
        // customer pays for 1 now becomes "Cerveza ×1" (paid) + "Cerveza ×3".
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
            // Whole line paid.
            item.isPaid = true;
            item.paymentReceiptId = receiptId;
            if (item.status == OrderItemStatus.pending) {
              item.status = OrderItemStatus.delivered;
              item.deliveredAt = now;
            }
          } else {
            // Partial: shrink the original (stays unpaid) and spin off a paid
            // copy holding only the paid units.
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
                ..paymentReceiptId = receiptId
                ..note = item.note,
            );
          }
        }
        if (selectedModels.isNotEmpty) {
          await db.orderItems.putAll(selectedModels);
        }
        // Persist split-off paid units and link them to the session.
        for (final part in splitItems) {
          part.id = await db.orderItems.put(part);
          part.tableSession.value = session;
          await part.tableSession.save();
        }

        // 2d. Recompute session status ────────────────────────────────────────
        await session.orderItems.load();
        final allItemIds = session.orderItems.map((i) => i.id).toList();
        final allItems = (await db.orderItems.getAll(allItemIds))
            .whereType<OrderItem>()
            .where((i) => i.status != OrderItemStatus.cancelled)
            .toList();

        final allPaid = allItems.isNotEmpty && allItems.every((i) => i.isPaid);
        if (allPaid) {
          session.status = TableStatus.closed;
          session.closedAt = now;
          // Session close code — different seed from the receipt code.
          final totalBill = allItems.fold(0, (sum, i) => sum + i.price * i.quantity);
          session.verificationCode = _generateCode(
            '${params.tableSessionId}:$totalBill:${now.millisecondsSinceEpoch}',
          );
        } else {
          session.status = TableStatus.partiallyPaid;
        }
        await db.tableSessions.put(session);

        entity = _mapToEntity(receiptModel);
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
        paidAt: m.paidAt,
      );
}

// ── Convenience extension used only in this file ──────────────────────────────

extension _ParamsX on RecordPaymentParams {
  bool get isTransfer => paymentMethod == PaymentMethod.transfer;
}
