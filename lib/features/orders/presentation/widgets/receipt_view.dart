import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/product_categories.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../domain/entities/order_item_entity.dart';

// ── Helpers de agrupación ──────────────────────────────────────────────────────

/// Ítems consumidos (no cancelados), ordenados por hora ascendente.
List<OrderItemEntity> consumedItems(List<OrderItemEntity> items) {
  final list = items.where((i) => !i.isCancelled).toList()
    ..sort((a, b) => a.orderedAt.compareTo(b.orderedAt));
  return list;
}

int receiptTotal(List<OrderItemEntity> items) =>
    consumedItems(items).fold(0, (s, i) => s + i.lineTotal);

int receiptPaid(List<OrderItemEntity> items) =>
    consumedItems(items).where((i) => i.isPaid).fold(0, (s, i) => s + i.lineTotal);

// ── Encabezado del tiquete ─────────────────────────────────────────────────────

class ReceiptHeader extends StatelessWidget {
  const ReceiptHeader({
    super.key,
    required this.barName,
    required this.tableNumber,
    required this.openedAt,
    this.apodo,
  });

  final String barName;
  final int tableNumber;
  final DateTime openedAt;
  final String? apodo;

  @override
  Widget build(BuildContext context) {
    final opened = DateFormat('HH:mm', 'es_CO').format(openedAt);
    final sub = [
      'Mesa $tableNumber',
      if (apodo != null && apodo!.isNotEmpty) '"$apodo"',
      'abierta $opened',
    ].join('  ·  ');

    return Column(
      children: [
        Text(
          barName.toUpperCase(),
          style: AppTextStyles.receiptTitle.copyWith(color: AppColors.paperInk),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: AppTextStyles.receiptSmall.copyWith(color: AppColors.paperInkSoft),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Línea de ítem ──────────────────────────────────────────────────────────────

class ReceiptItemLine extends StatelessWidget {
  const ReceiptItemLine({
    super.key,
    required this.quantity,
    required this.name,
    required this.total,
    this.note,
    this.statusColor,
    this.onLongPress,
    this.unitLabel,
  });

  final int quantity;
  final String name;
  final int total;
  final String? note;
  final Color? statusColor;
  final VoidCallback? onLongPress;

  /// Ej. "$8.000 c/u" para líneas agrupadas.
  final String? unitLabel;

  @override
  Widget build(BuildContext context) {
    final line = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (statusColor != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 5, right: 6),
                  child: Icon(Icons.circle, size: 8, color: statusColor),
                ),
              ],
              Expanded(
                child: Text(
                  '${quantity}× $name',
                  style: AppTextStyles.receiptBody
                      .copyWith(color: AppColors.paperInk),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                total.toCop,
                style: AppTextStyles.receiptBodyBold
                    .copyWith(color: AppColors.paperInk),
              ),
            ],
          ),
          if (unitLabel != null)
            Padding(
              padding: const EdgeInsets.only(left: 0, top: 1),
              child: Text(
                unitLabel!,
                style: AppTextStyles.receiptSmall
                    .copyWith(color: AppColors.paperInkSoft),
              ),
            ),
          if (note != null && note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                '↳ $note',
                style: AppTextStyles.receiptSmall.copyWith(
                  color: AppColors.paperInkSoft,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );

    if (onLongPress == null) return line;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: line,
    );
  }
}

// ── Vista cronológica (bloques por hora) ───────────────────────────────────────

class ReceiptChronological extends StatelessWidget {
  const ReceiptChronological({
    super.key,
    required this.items,
    this.onLongPressItem,
  });

  final List<OrderItemEntity> items;
  final void Function(OrderItemEntity item)? onLongPressItem;

  @override
  Widget build(BuildContext context) {
    final consumed = consumedItems(items);
    if (consumed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Mesa vacía — agrega el primer ítem.',
          style: AppTextStyles.receiptBody.copyWith(color: AppColors.paperInkSoft),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Agrupar por bloque de hora (HH:mm), preservando el orden temporal.
    final blocks = <String, List<OrderItemEntity>>{};
    for (final it in consumed) {
      final key = DateFormat('HH:mm', 'es_CO').format(it.orderedAt);
      blocks.putIfAbsent(key, () => []).add(it);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in blocks.entries) ...[
          _TimeHeader(label: entry.key),
          for (final it in entry.value)
            ReceiptItemLine(
              quantity: it.quantity,
              name: it.productName,
              total: it.lineTotal,
              note: it.note,
              statusColor: _statusColor(it),
              onLongPress: onLongPressItem == null
                  ? null
                  : () => onLongPressItem!(it),
            ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _TimeHeader extends StatelessWidget {
  const _TimeHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.receiptSmall.copyWith(
              color: AppColors.paperInkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: DashedDivider(
              padding: EdgeInsets.zero,
              dashWidth: 4,
              dashGap: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vista agrupada (por categoría) ─────────────────────────────────────────────

class ReceiptGrouped extends StatelessWidget {
  const ReceiptGrouped({super.key, required this.items});

  final List<OrderItemEntity> items;

  @override
  Widget build(BuildContext context) {
    final consumed = consumedItems(items);
    if (consumed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Mesa vacía.',
          style: AppTextStyles.receiptBody.copyWith(color: AppColors.paperInkSoft),
          textAlign: TextAlign.center,
        ),
      );
    }

    // categoría → (producto → [qty, total, unitPrice])
    final byCat = <String, List<OrderItemEntity>>{};
    for (final it in consumed) {
      byCat.putIfAbsent(it.menuCategoryOrOther, () => []).add(it);
    }
    final cats = byCat.keys.toList()
      ..sort((a, b) => categorySortIndex(a).compareTo(categorySortIndex(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final cat in cats) ...[
          _CategoryHeader(
            label: cat,
            count: byCat[cat]!.fold(0, (s, i) => s + i.quantity),
            subtotal: byCat[cat]!.fold(0, (s, i) => s + i.lineTotal),
          ),
          ..._collapseByProduct(byCat[cat]!),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  List<Widget> _collapseByProduct(List<OrderItemEntity> catItems) {
    final map = <String, List<int>>{}; // name → [qty, total, unitPrice]
    for (final it in catItems) {
      final e = map.putIfAbsent(it.productName, () => [0, 0, it.price]);
      e[0] += it.quantity;
      e[1] += it.lineTotal;
    }
    return map.entries.map((e) {
      return ReceiptItemLine(
        quantity: e.value[0],
        name: e.key,
        total: e.value[1],
        unitLabel: '${e.value[2].toCop} c/u',
      );
    }).toList();
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.label,
    required this.count,
    required this.subtotal,
  });

  final String label;
  final int count;
  final int subtotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Row(
        children: [
          Text(
            '${label.toUpperCase()} ($count)',
            style: AppTextStyles.receiptBodyBold.copyWith(color: AppColors.paperInk),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: DashedDivider(padding: EdgeInsets.zero, dashWidth: 4, dashGap: 4),
          ),
          const SizedBox(width: 8),
          Text(
            subtotal.toCop,
            style: AppTextStyles.receiptBodyBold.copyWith(color: AppColors.paperInk),
          ),
        ],
      ),
    );
  }
}

// ── Footer TOTAL / pagado / SALDO ──────────────────────────────────────────────

class ReceiptFooter extends StatelessWidget {
  const ReceiptFooter({super.key, required this.items, this.showThanks = false});

  final List<OrderItemEntity> items;
  final bool showThanks;

  @override
  Widget build(BuildContext context) {
    final total = receiptTotal(items);
    final paid = receiptPaid(items);
    final saldo = total - paid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FooterRow(label: 'TOTAL', value: total.toCop, bold: true),
        if (paid > 0)
          _FooterRow(
            label: 'pagado',
            value: '-${paid.toCop}',
            color: AppColors.secondaryDark,
          ),
        if (paid > 0)
          _FooterRow(
            label: 'SALDO',
            value: saldo.toCop,
            bold: true,
            color: saldo == 0 ? AppColors.secondaryDark : AppColors.paperInk,
          ),
        if (showThanks) ...[
          const SizedBox(height: 12),
          Text(
            '¡gracias por venir!',
            style: AppTextStyles.receiptSmall.copyWith(color: AppColors.paperInkSoft),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color = AppColors.paperInk,
  });

  final String label;
  final String value;
  final bool bold;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = (bold ? AppTextStyles.receiptTotal : AppTextStyles.receiptBody)
        .copyWith(color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

// ── Utilidad de estado ─────────────────────────────────────────────────────────

Color? _statusColor(OrderItemEntity it) {
  if (it.isPaid) return AppColors.secondary;      // pagado
  if (it.isActive) return AppColors.statusOrange; // pendiente en cocina
  return AppColors.statusBlue;                     // entregado sin pagar
}

/// Construye el texto plano del tiquete para compartir.
String buildReceiptText({
  required String barName,
  required int tableNumber,
  String? apodo,
  required DateTime openedAt,
  required List<OrderItemEntity> items,
  required bool grouped,
}) {
  final b = StringBuffer();
  final consumed = consumedItems(items);
  b.writeln(barName.toUpperCase());
  final opened = DateFormat('HH:mm', 'es_CO').format(openedAt);
  b.writeln('Mesa $tableNumber${apodo != null && apodo.isNotEmpty ? ' "$apodo"' : ''} · abierta $opened');
  b.writeln('------------------------------');

  if (grouped) {
    final byCat = <String, List<OrderItemEntity>>{};
    for (final it in consumed) {
      byCat.putIfAbsent(it.menuCategoryOrOther, () => []).add(it);
    }
    final cats = byCat.keys.toList()
      ..sort((a, b) => categorySortIndex(a).compareTo(categorySortIndex(b)));
    for (final cat in cats) {
      final catItems = byCat[cat]!;
      final count = catItems.fold(0, (s, i) => s + i.quantity);
      final sub = catItems.fold(0, (s, i) => s + i.lineTotal);
      b.writeln('${cat.toUpperCase()} ($count)  ${sub.toCop}');
      final map = <String, List<int>>{};
      for (final it in catItems) {
        final e = map.putIfAbsent(it.productName, () => [0, 0]);
        e[0] += it.quantity;
        e[1] += it.lineTotal;
      }
      for (final e in map.entries) {
        b.writeln('  ${e.value[0]}× ${e.key}  ${e.value[1].toCop}');
      }
    }
  } else {
    final blocks = <String, List<OrderItemEntity>>{};
    for (final it in consumed) {
      final key = DateFormat('HH:mm', 'es_CO').format(it.orderedAt);
      blocks.putIfAbsent(key, () => []).add(it);
    }
    for (final entry in blocks.entries) {
      b.writeln(entry.key);
      for (final it in entry.value) {
        b.writeln('  ${it.quantity}× ${it.productName}  ${it.lineTotal.toCop}');
      }
    }
  }

  b.writeln('------------------------------');
  final total = receiptTotal(items);
  final paid = receiptPaid(items);
  b.writeln('TOTAL  ${total.toCop}');
  if (paid > 0) {
    b.writeln('pagado  -${paid.toCop}');
    b.writeln('SALDO  ${(total - paid).toCop}');
  }
  return b.toString();
}
