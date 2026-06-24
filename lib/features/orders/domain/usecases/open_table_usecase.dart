import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../tables/domain/entities/table_session_entity.dart';
import '../repositories/i_order_repository.dart';

/// Opens a new table session for a customer group.
///
/// ── Business rules enforced ───────────────────────────────────────────────────
/// 1. Table number must be a positive integer.
/// 2. A table with the same number cannot already be open or partially paid —
///    there can only be one active session per table number at a time.
/// 3. [apodo] is optional; when provided it is stored privately and never
///    appears on any printed receipt or cloud record.
final class OpenTableUseCase {
  const OpenTableUseCase(this._repository);

  final IOrderRepository _repository;

  Future<Result<TableSessionEntity>> call({
    required int tableNumber,
    String? apodo,
  }) async {
    if (tableNumber <= 0) {
      return Err(
        const ValidationFailure(
          message: 'El número de mesa debe ser mayor que cero.',
        ),
      );
    }

    // Guard: check for an already-active session on this table number.
    final activeResult = await _repository.getActiveSessions();
    if (activeResult.isErr) return activeResult.map((_) => throw UnimplementedError());

    final activeSessions = (activeResult as Ok).value as List<TableSessionEntity>;
    final alreadyOpen = activeSessions.any((s) => s.tableNumber == tableNumber);

    if (alreadyOpen) {
      return Err(
        BusinessRuleFailure(
          message: 'La Mesa $tableNumber ya tiene una sesión activa. '
              'Cierra o finaliza la sesión anterior antes de abrir una nueva.',
        ),
      );
    }

    return _repository.openTable(tableNumber: tableNumber, apodo: apodo);
  }
}
