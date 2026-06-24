/// Sealed failure hierarchy for the entire application.
///
/// Every repository returns `Either<Failure, T>` — callers switch on this
/// sealed class to handle all error scenarios exhaustively at compile time.
///
/// Rule: do NOT throw exceptions across layer boundaries. Convert them to
/// [Failure] subtypes at the data layer and propagate up via the return type.
sealed class Failure {
  const Failure({required this.message, this.stackTrace});

  final String message;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

// ── Infrastructure ─────────────────────────────────────────────────────────

/// Isar database read/write error.
final class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.stackTrace});
}

/// Supabase or general network error.
final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.stackTrace});
}

/// Supabase Storage upload/download error.
final class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.stackTrace});
}

// ── Device / Permissions ───────────────────────────────────────────────────

/// Camera unavailable or permission denied.
final class CameraFailure extends Failure {
  const CameraFailure({required super.message, super.stackTrace});
}

/// File system read/write error (e.g. saving to Bonanza_Transferencias).
final class FileSystemFailure extends Failure {
  const FileSystemFailure({required super.message, super.stackTrace});
}

/// Required OS permission was denied by the user.
final class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.stackTrace});
}

// ── Domain / Business Logic ────────────────────────────────────────────────

/// Input did not satisfy a validation rule (e.g. negative amount, blank name).
final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.stackTrace});
}

/// An operation was blocked by a business rule (e.g. Cierre Blindado).
final class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure({required super.message, super.stackTrace});

  /// Specific Cierre Blindado sub-failures for UI granularity.
  static const cierreOpenRadarItems = BusinessRuleFailure(
    message: 'Hay pedidos pendientes en El Radar.',
  );
  static const cierreUnpaidTables = BusinessRuleFailure(
    message: 'Hay mesas con saldo pendiente.',
  );
  static const cierreUnverifiedTransfers = BusinessRuleFailure(
    message: 'Hay transferencias sin legalizar.',
  );
}

/// The requested resource was not found in local DB or remote.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.stackTrace});
}

/// Unexpected state that should never occur in a correct program flow.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.stackTrace});
}

// ── Helper extension ──────────────────────────────────────────────────────

extension FailureX on Failure {
  /// Whether this failure is recoverable by retrying (e.g. network issues).
  bool get isRetryable => switch (this) {
        NetworkFailure() => true,
        StorageFailure() => true,
        DatabaseFailure() => false,
        CameraFailure() => true,
        FileSystemFailure() => false,
        PermissionFailure() => false,
        ValidationFailure() => false,
        BusinessRuleFailure() => false,
        NotFoundFailure() => false,
        UnexpectedFailure() => false,
      };
}
