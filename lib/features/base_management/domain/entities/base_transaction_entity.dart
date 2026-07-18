import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pure domain representation of a single financial event in the waiter's
/// ledger. Has no Isar annotations and no Flutter dependencies except for
/// the display helpers used exclusively by the presentation layer.
///
/// Mapped from [WaiterBaseTransaction] (Isar model) by the repository.
final class BaseTransactionEntity {
  const BaseTransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.note,
  });

  final int id;
  final TransactionType type;

  /// Amount in COP. Always a positive integer — [type] carries the sign semantics.
  final int amount;

  /// Exact timestamp. Required by business rule for increase audit trail.
  final DateTime timestamp;

  final String? note;

  // ── Display helpers (presentation-layer only, no business logic) ──────────

  String get displayLabel => switch (type) {
        TransactionType.initial => 'Base Inicial',
        TransactionType.increase => 'Incremento de Base',
        TransactionType.decrease => 'Reducción de Base',
        TransactionType.liquorAdjustment => 'Deuda por Licor',
        TransactionType.liquorSettlement => 'Botella Completada',
      };

  String get displayPrefix => switch (type) {
        TransactionType.initial => '+',
        TransactionType.increase => '+',
        TransactionType.decrease => '−',
        TransactionType.liquorAdjustment => '+', // adds to debt, displayed positive
        TransactionType.liquorSettlement => '−', // reduces liquor debt
      };

  Color get displayColor => switch (type) {
        TransactionType.initial => AppColors.statusGreen,
        TransactionType.increase => AppColors.brand,
        TransactionType.decrease => AppColors.statusOrange,
        TransactionType.liquorAdjustment => AppColors.statusPurple,
        TransactionType.liquorSettlement => AppColors.statusGreen,
      };

  IconData get displayIcon => switch (type) {
        TransactionType.initial => Icons.account_balance_wallet_rounded,
        TransactionType.increase => Icons.trending_up_rounded,
        TransactionType.decrease => Icons.trending_down_rounded,
        TransactionType.liquorAdjustment => Icons.wine_bar_rounded,
        TransactionType.liquorSettlement => Icons.check_circle_rounded,
      };

  BaseTransactionEntity copyWith({
    int? id,
    TransactionType? type,
    int? amount,
    DateTime? timestamp,
    String? note,
  }) =>
      BaseTransactionEntity(
        id: id ?? this.id,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        timestamp: timestamp ?? this.timestamp,
        note: note ?? this.note,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseTransactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BaseTransactionEntity(id: $id, type: $type, amount: $amount)';
}

// ── TransactionType ──────────────────────────────────────────────────────────
//
// Defined in the DOMAIN layer so both domain entities and the Isar data model
// can import from here without violating the dependency rule:
//   domain ← data  (data imports domain: ✓)
//   domain → data  (domain imports data: ✗ — never allowed)

/// Discriminates every type of financial event in the waiter's base ledger.
enum TransactionType {
  /// The one-time $300,000 COP starting base created when the shift opens.
  initial,

  /// A manual $100,000 COP increment authorized during the shift.
  increase,

  /// A manual $100,000 COP reduction — mirrors [increase] in reverse.
  /// Reduces baseCapital, totalDebt, AND availableBalance.
  decrease,

  /// The cost of a liquor bottle charged directly to the waiter's debt.
  /// Does NOT reduce Available Base Balance — only inflates Total Debt.
  liquorAdjustment,

  /// Saldo de una botella "completada" (pagada en barra / caja).
  /// Reduce la deuda de licor (contrapartida de [liquorAdjustment]). No toca
  /// el saldo disponible ni el efectivo del mesero: la botella es pass-through.
  liquorSettlement,
}
