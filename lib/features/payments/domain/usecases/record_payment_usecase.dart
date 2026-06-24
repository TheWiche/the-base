import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/payment_receipt_entity.dart';
import '../repositories/i_payment_repository.dart';

/// Validates the payment intent and delegates the atomic write to the repository.
///
/// Business rules enforced here (not in the repository):
///   • At least one item must be selected.
///   • Amount received must be positive.
///   • For cash: amount received must equal or exceed the bill subtotal.
///   • Constructor-level asserts on [RecordPaymentParams] enforce photo + method
///     requirements for transfers — those invariants are checked at compile time.
final class RecordPaymentUseCase {
  const RecordPaymentUseCase(this._repository);

  final IPaymentRepository _repository;

  Future<Result<PaymentReceiptEntity>> call(RecordPaymentParams params) async {
    if (params.selectedItemIds.isEmpty) {
      return err(
        const ValidationFailure(
          message: 'Selecciona al menos un ítem para cobrar.',
        ),
      );
    }

    if (params.amountPaid <= 0) {
      return err(
        const ValidationFailure(
          message: 'El monto recibido debe ser mayor a cero.',
        ),
      );
    }

    if (params.paymentMethod == PaymentMethod.cash &&
        params.amountPaid < params.billSubtotal) {
      return err(
        const ValidationFailure(
          message: 'El efectivo recibido es insuficiente para cubrir la cuenta. '
              'Verifica el monto.',
        ),
      );
    }

    return _repository.recordPayment(params);
  }
}
