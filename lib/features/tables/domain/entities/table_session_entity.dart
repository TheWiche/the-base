import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pure domain entity representing one customer group's visit at a table.
/// Mapped from [TableSession] (Isar model) by the order repository.
final class TableSessionEntity {
  const TableSessionEntity({
    required this.id,
    required this.tableNumber,
    required this.status,
    required this.openedAt,
    this.apodo,
    this.closedAt,
    this.verificationCode,
  });

  final int id;
  final int tableNumber;

  /// Private nickname visible only to the waiter (never on receipts).
  final String? apodo;
  final TableStatus status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String? verificationCode;

  // ── Display helpers ────────────────────────────────────────────────────────

  /// "Mesa 5" or "Mesa 5 — Los cumpleañeros"
  String get displayLabel {
    final base = 'Mesa $tableNumber';
    return apodo != null ? '$base — "$apodo"' : base;
  }

  String get shortLabel => 'Mesa $tableNumber';

  Color get statusColor => switch (status) {
        TableStatus.open => AppColors.statusGreen,
        TableStatus.partiallyPaid => AppColors.statusOrange,
        TableStatus.closed => AppColors.darkDisabled,
      };

  String get statusLabel => switch (status) {
        TableStatus.open => 'Abierta',
        TableStatus.partiallyPaid => 'Pago Parcial',
        TableStatus.closed => 'Cerrada',
      };

  bool get isActive =>
      status == TableStatus.open || status == TableStatus.partiallyPaid;

  TableSessionEntity copyWith({
    int? id,
    int? tableNumber,
    String? apodo,
    TableStatus? status,
    DateTime? openedAt,
    DateTime? closedAt,
    String? verificationCode,
  }) =>
      TableSessionEntity(
        id: id ?? this.id,
        tableNumber: tableNumber ?? this.tableNumber,
        apodo: apodo ?? this.apodo,
        status: status ?? this.status,
        openedAt: openedAt ?? this.openedAt,
        closedAt: closedAt ?? this.closedAt,
        verificationCode: verificationCode ?? this.verificationCode,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableSessionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ── TableStatus ───────────────────────────────────────────────────────────────
// Defined in the DOMAIN layer. Data models import from here.

/// Lifecycle state of a [TableSessionEntity].
/// Transitions are enforced by use cases — never mutate status in the UI.
enum TableStatus {
  /// Table is actively being served. New items can be added.
  open,

  /// At least one payment received but unpaid items remain.
  partiallyPaid,

  /// All items settled. No new items or payments accepted.
  closed,
}
