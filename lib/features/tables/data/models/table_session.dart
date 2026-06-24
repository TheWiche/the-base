import 'package:isar/isar.dart';

// Enums are defined in the DOMAIN layer — data → domain import is correct.
import '../../domain/entities/table_session_entity.dart';
import '../../../billing/data/models/payment_receipt.dart';
import '../../../orders/data/models/order_item.dart';

part 'table_session.g.dart';

/// Isar collection representing one customer group's visit at a table.
/// The root aggregate for all order items and payment receipts.
///
/// Relation graph:
///   TableSession 1 ──< OrderItem      (via [orderItems] link)
///   TableSession 1 ──< PaymentReceipt (via [payments] link)
///
/// Status transitions (enforced by use cases, never in the UI):
///   open → partiallyPaid → closed
///   open → closed  (full payment in one go)
@collection
class TableSession {
  Id id = Isar.autoIncrement;

  /// Physical table number. Indexed for fast lookup by table number.
  @Index()
  late int tableNumber;

  /// Private nickname — never on receipts, never sent to the cloud.
  String? apodo;

  @Index()
  @enumerated
  late TableStatus status;

  /// Indexed for daily report date-range queries.
  @Index()
  late DateTime openedAt;

  DateTime? closedAt;

  /// SHA-256-derived 8-digit code generated at close for cashier reconciliation.
  String? verificationCode;

  // ── Relations ──────────────────────────────────────────────────────────────
  final orderItems = IsarLinks<OrderItem>();
  final payments = IsarLinks<PaymentReceipt>();
}
