import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pure domain entity for a single product line on a table order.
/// Mapped from [OrderItem] (Isar model) by the order repository.
final class OrderItemEntity {
  const OrderItemEntity({
    required this.id,
    required this.tableSessionId,
    required this.productName,
    this.productCatalogId,
    required this.price,
    required this.quantity,
    required this.category,
    required this.orderedAt,
    required this.status,
    required this.isPaid,
    this.deliveredAt,
    this.paymentReceiptId,
    this.note,
  });

  final int id;
  final int tableSessionId;
  final String productName;

  /// Null for custom (manually typed) items.
  final String? productCatalogId;

  /// COP price per unit — snapshot at order time, never updated retroactively.
  final int price;
  final int quantity;

  /// Drives financial routing. See [ProductCategory] docs.
  final ProductCategory category;

  /// Exact timestamp used by El Radar for elapsed-time computation.
  final DateTime orderedAt;
  final DateTime? deliveredAt;
  final OrderItemStatus status;
  final bool isPaid;
  final int? paymentReceiptId;

  /// Optional free-text note for the kitchen/bar (e.g. "sin hielo, con limón").
  final String? note;

  // ── Computed ───────────────────────────────────────────────────────────────

  int get lineTotal => price * quantity;
  bool get isLiquor => category == ProductCategory.liquor;
  bool get isActive => status == OrderItemStatus.pending;
  bool get isCancelled => status == OrderItemStatus.cancelled;
  bool get isDelivered => status == OrderItemStatus.delivered;

  /// Elapsed time since order was placed — drives El Radar urgency coloring.
  Duration get elapsed => DateTime.now().difference(orderedAt);
  int get elapsedMinutes => elapsed.inMinutes;

  /// Urgency level for El Radar visual cues.
  RadarUrgency get urgency {
    final minutes = elapsedMinutes;
    if (minutes < 5) return RadarUrgency.normal;
    if (minutes < 10) return RadarUrgency.warning;
    return RadarUrgency.critical;
  }

  // ── Display helpers ────────────────────────────────────────────────────────

  Color get categoryColor => switch (category) {
        ProductCategory.standard => AppColors.statusGreen,
        ProductCategory.liquor => AppColors.statusPurple,
      };

  IconData get categoryIcon => switch (category) {
        ProductCategory.standard => Icons.local_drink_rounded,
        ProductCategory.liquor => Icons.wine_bar_rounded,
      };

  String get statusLabel => switch (status) {
        OrderItemStatus.pending => 'Pendiente',
        OrderItemStatus.delivered => 'Entregado',
        OrderItemStatus.cancelled => 'Cancelado',
      };

  OrderItemEntity copyWith({
    int? id,
    int? tableSessionId,
    String? productName,
    String? productCatalogId,
    int? price,
    int? quantity,
    ProductCategory? category,
    DateTime? orderedAt,
    DateTime? deliveredAt,
    OrderItemStatus? status,
    bool? isPaid,
    int? paymentReceiptId,
    String? note,
  }) =>
      OrderItemEntity(
        id: id ?? this.id,
        tableSessionId: tableSessionId ?? this.tableSessionId,
        productName: productName ?? this.productName,
        productCatalogId: productCatalogId ?? this.productCatalogId,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
        category: category ?? this.category,
        orderedAt: orderedAt ?? this.orderedAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        status: status ?? this.status,
        isPaid: isPaid ?? this.isPaid,
        paymentReceiptId: paymentReceiptId ?? this.paymentReceiptId,
        note: note ?? this.note,
      );

  /// Builds the params to re-order this exact line as a fresh pending item
  /// (used by "repetir ítem" / "repetir ronda").
  AddItemParams toAddItemParams() => AddItemParams(
        tableSessionId: tableSessionId,
        productName: productName,
        price: price,
        quantity: quantity,
        category: category,
        productCatalogId: productCatalogId,
        note: note,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OrderItemEntity($productName ×$quantity = \$$lineTotal)';
}

// ── Enums ─────────────────────────────────────────────────────────────────────

/// Financial routing category — the most critical business-rule discriminator.
enum ProductCategory {
  /// Coffee, food, soft drinks.
  /// Cost subtracted from waiter's Available Base Balance.
  standard,

  /// Bottles of liquor.
  /// Cost added to Total Debt ONLY — does NOT reduce Available Balance.
  /// Triggers a simultaneous [WaiterBaseTransaction.liquorAdjustment] write.
  liquor,
}

/// KDS lifecycle state of an [OrderItemEntity].
enum OrderItemStatus {
  /// In the queue — visible and counted in El Radar.
  pending,

  /// Handed to customer — [deliveredAt] is stamped, removed from radar.
  delivered,

  /// Voided. Shown with strikethrough in the order screen, excluded from billing.
  cancelled,
}

/// Urgency level for El Radar color-coding.
enum RadarUrgency {
  normal,   // < 5 min  → neutral
  warning,  // 5–9 min  → orange
  critical, // 10+ min  → red
}

// ── AddItemParams ─────────────────────────────────────────────────────────────

/// Input DTO for [AddOrderItemUseCase].
final class AddItemParams {
  const AddItemParams({
    required this.tableSessionId,
    required this.productName,
    required this.price,
    required this.category,
    this.productCatalogId,
    this.quantity = 1,
    this.note,
  }) : assert(price > 0, 'price must be positive'),
       assert(quantity >= 1, 'quantity must be at least 1');

  final int tableSessionId;
  final String productName;

  /// Null for custom/freeform items typed manually by the waiter.
  final String? productCatalogId;

  /// COP price per unit.
  final int price;
  final int quantity;
  final ProductCategory category;

  /// Optional free-text note for the kitchen/bar.
  final String? note;

  int get lineTotal => price * quantity;

  bool get isLiquor => category == ProductCategory.liquor;
  bool get isCustomItem => productCatalogId == null;
}
