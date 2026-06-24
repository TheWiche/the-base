import 'package:isar/isar.dart';

// Enums are defined in the DOMAIN layer — data → domain import is correct.
import '../../domain/entities/order_item_entity.dart';
import '../../../tables/data/models/table_session.dart';

part 'order_item.g.dart';

/// Isar collection for a single product line on a table's order.
/// Mapped to [OrderItemEntity] by [OrderRepositoryImpl].
///
/// ── Financial routing note ────────────────────────────────────────────────────
/// [category] is the key field: when == [ProductCategory.liquor], the repository
/// writes a concurrent [WaiterBaseTransaction.liquorAdjustment] in the same
/// Isar transaction. The [price × quantity] cost hits Total Debt immediately
/// but does NOT reduce Available Base Balance.
///
/// ── Indexes ──────────────────────────────────────────────────────────────────
/// Composite (tableSessionId, isPaid): "unpaid items for this table" — billing.
/// Individual (orderedAt): chronological sort for El Radar.
/// Individual (status): El Radar pending filter + Cierre Blindado check.
@collection
class OrderItem {
  Id id = Isar.autoIncrement;

  /// FK to parent [TableSession]. Composite-indexed with [isPaid].
  @Index(composite: [CompositeIndex('isPaid')])
  late int tableSessionId;

  late String productName;
  String? productCatalogId;

  /// COP price snapshot — never updated after order placement.
  late int price;
  late int quantity;

  @enumerated
  late ProductCategory category;

  /// Exact timestamp for El Radar's elapsed-time counter.
  @Index()
  late DateTime orderedAt;

  DateTime? deliveredAt;

  @Index()
  @enumerated
  late OrderItemStatus status;

  @Index()
  late bool isPaid;

  int? paymentReceiptId;

  /// Optional free-text note for the kitchen/bar (e.g. "sin hielo, con limón").
  String? note;

  // ── Back-link to parent session ───────────────────────────────────────────
  @Backlink(to: 'orderItems')
  final tableSession = IsarLink<TableSession>();
}
