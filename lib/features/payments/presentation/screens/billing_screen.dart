import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/settings/bar_settings_provider.dart';
import '../../../../core/settings/category_order_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../orders/presentation/widgets/factura_sheet.dart';
import '../../../orders/presentation/widgets/receipt_view.dart';
import '../../../tables/domain/entities/table_session_entity.dart';
import '../../domain/entities/billing_selection.dart';
import '../../domain/entities/payment_receipt_entity.dart';
import '../providers/payment_providers.dart';

/// Pantalla de Cobrar — estilo tiquete.
///
/// El cliente puede ver esta pantalla: NO se muestra el apodo de la mesa.
/// Toggle Cronológica (bloques por hora) / Agrupada (por categoría).
/// Los ítems se seleccionan por toque; botellas de licor se "Completan"
/// (pass-through). Barra inferior: total seleccionado + Cobrar.
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  /// Cache: la sesión puede cerrarse (todo pagado) y salir del stream de
  /// activas — sin cache la pantalla quedaba cargando para siempre (bug v1.5.0).
  TableSessionEntity? _session;

  /// 0 = cronológica (bloques por hora) · 1 = agrupada (por categoría).
  int _mode = 0;

  /// Categorías plegadas en la vista agrupada (flechita del encabezado).
  final _collapsedCats = <String>{};

  int get sessionId => widget.sessionId;

  /// Auto-pop seguro: solo cuando esta ruta está al frente (si dispara con la
  /// pantalla de transferencia encima, cerraría la ruta equivocada).
  void _maybeAutoPop(List<OrderItemEntity> items) {
    final billable = items.where((i) => !i.isCancelled).toList();
    final unpaid = billable.where((i) => !i.isPaid).toList();
    if (billable.isEmpty || unpaid.isNotEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      if (context.canPop()) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(tableOrderProvider(sessionId));
    final sessionLive = ref.watch(tableSessionByIdProvider(sessionId));
    if (sessionLive != null) _session = sessionLive;
    final barName = ref.watch(barNameProvider);
    final selection = ref.watch(billingSelectionProvider(sessionId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cambios en caliente (pago registrado con esta pantalla cubierta).
    ref.listen(tableOrderProvider(sessionId), (_, next) {
      next.whenData(_maybeAutoPop);
    });
    // Reevaluar al reconstruir (p. ej. al volver de la transferencia).
    itemsAsync.whenData(_maybeAutoPop);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _session == null ? 'Cobrar' : 'Cobrar — Mesa ${_session!.tableNumber}',
          style: AppTextStyles.headlineSmall,
        ),
        actions: [
          IconButton(
            tooltip: 'Compartir factura',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => FacturaSheet.show(context, sessionId),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (items) {
          final billable = items.where((i) => !i.isCancelled).toList();
          final unpaid = billable.where((i) => !i.isPaid).toList();
          final selectableItems = unpaid.where((i) => !i.isLiquor).toList()
            ..sort((a, b) => a.orderedAt.compareTo(b.orderedAt));
          final liquorItems = unpaid.where((i) => i.isLiquor).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: PillToggle(
                  options: const ['Cronológica', 'Agrupada'],
                  selectedIndex: _mode,
                  onChanged: (i) => setState(() => _mode = i),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _BillingReceipt(
                  barName: barName,
                  session: _session,
                  grouped: _mode == 1,
                  categoryOrder: ref.watch(categoryOrderProvider.notifier),
                  selectableItems: selectableItems,
                  liquorItems: liquorItems,
                  selection: selection,
                  collapsedCats: _collapsedCats,
                  onToggleCat: (cat) => setState(() {
                    _collapsedCats.contains(cat)
                        ? _collapsedCats.remove(cat)
                        : _collapsedCats.add(cat);
                  }),
                  onToggle: (item) => ref
                      .read(billingSelectionProvider(sessionId).notifier)
                      .toggle(item.id, item.quantity),
                  onCompletar: _settleLiquor,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: itemsAsync.maybeWhen(
        data: (items) {
          final selectable = items
              .where((i) => !i.isCancelled && !i.isPaid && !i.isLiquor)
              .toList();
          if (selectable.isEmpty) return const SizedBox.shrink();
          final subtotal = selection.subtotalOf(selectable);
          return _BottomBar(
            subtotal: subtotal,
            selectedCount: selection.count,
            onSelectAll: () => ref
                .read(billingSelectionProvider(sessionId).notifier)
                .selectAll({for (final i in selectable) i.id: i.quantity}),
            onClearAll: () => ref
                .read(billingSelectionProvider(sessionId).notifier)
                .clearAll(),
            onCobrar: subtotal > 0
                ? () => _showPaymentMethodSheet(subtotal: subtotal)
                : null,
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _settleLiquor(OrderItemEntity item) async {
    final failure = await ref
        .read(tableOrderProvider(sessionId).notifier)
        .settleLiquor(item.id);
    if (!mounted) return;
    if (failure != null) {
      AppToast.error(context, failure.message);
    } else {
      AppToast.success(context, 'Botella completada: ${item.productName}');
    }
  }

  // ── Payment method sheet ─────────────────────────────────────────────────────

  void _showPaymentMethodSheet({required int subtotal}) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentMethodSheet(
        subtotal: subtotal,
        onSelected: (method) {
          Navigator.of(context).pop();
          _navigateToPayment(method: method, subtotal: subtotal);
        },
        onExact: () {
          Navigator.of(context).pop();
          _recordExactCash(subtotal: subtotal);
        },
      ),
    );
  }

  void _navigateToPayment({
    required PaymentMethod method,
    required int subtotal,
  }) {
    final selection = ref.read(billingSelectionProvider(sessionId));
    final quantities = selection.selectedQuantities;
    final args = PaymentNavigationArgs(
      sessionId: sessionId,
      selectedItemIds: quantities.keys.toList(),
      selectedQuantities: quantities,
      billSubtotal: subtotal,
    );
    final path = method == PaymentMethod.cash
        ? '/billing/$sessionId/cash'
        : '/billing/$sessionId/transfer';
    context.push(path, extra: args);
  }

  /// Pago exacto: efectivo por el total sin escribir monto.
  Future<void> _recordExactCash({required int subtotal}) async {
    final selection = ref.read(billingSelectionProvider(sessionId));
    final quantities = selection.selectedQuantities;
    if (quantities.isEmpty) return;

    final params = RecordPaymentParams(
      tableSessionId: sessionId,
      selectedItemIds: quantities.keys.toList(),
      selectedQuantities: quantities,
      amountPaid: subtotal,
      billSubtotal: subtotal,
      paymentMethod: PaymentMethod.cash,
    );
    final failure =
        await ref.read(paymentNotifierProvider.notifier).recordPayment(params);
    if (!mounted) return;
    if (failure != null) {
      AppToast.error(context, failure.message);
      return;
    }
    ref.read(billingSelectionProvider(sessionId).notifier).clearAll();
    AppToast.success(context, 'Pago exacto registrado: ${subtotal.toCop}');
  }
}

// ── Recibo de cobro ──────────────────────────────────────────────────────────

class _BillingReceipt extends StatelessWidget {
  const _BillingReceipt({
    required this.barName,
    required this.session,
    required this.grouped,
    required this.categoryOrder,
    required this.selectableItems,
    required this.liquorItems,
    required this.selection,
    required this.collapsedCats,
    required this.onToggleCat,
    required this.onToggle,
    required this.onCompletar,
  });

  final String barName;
  final TableSessionEntity? session;
  final bool grouped;
  final CategoryOrderNotifier categoryOrder;
  final List<OrderItemEntity> selectableItems;
  final List<OrderItemEntity> liquorItems;
  final BillingSelection selection;
  final Set<String> collapsedCats;
  final void Function(String) onToggleCat;
  final void Function(OrderItemEntity) onToggle;
  final void Function(OrderItemEntity) onCompletar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ReceiptPaper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session != null)
              ReceiptHeader(
                barName: barName,
                tableNumber: session!.tableNumber,
                // Sin apodo: el cliente puede ver esta pantalla.
                apodo: null,
                openedAt: session!.openedAt,
              )
            else
              Text(
                barName.toUpperCase(),
                style: AppTextStyles.receiptTitle
                    .copyWith(color: AppColors.paperInk),
                textAlign: TextAlign.center,
              ),
            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
            Text(
              'TOCA PARA SELECCIONAR',
              style: AppTextStyles.receiptSmall
                  .copyWith(color: AppColors.paperInkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            if (grouped)
              ..._buildGrouped(context)
            else
              ..._buildChronological(context),
            if (selectableItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  liquorItems.isEmpty
                      ? 'Nada por cobrar.'
                      : 'Nada por cobrar (solo botellas).',
                  style: AppTextStyles.receiptBody
                      .copyWith(color: AppColors.paperInkSoft),
                  textAlign: TextAlign.center,
                ),
              ),
            if (liquorItems.isNotEmpty) ...[
              const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
              Text(
                'BOTELLAS · van a barra',
                style: AppTextStyles.receiptBodyBold
                    .copyWith(color: AppColors.statusPurple),
              ),
              const SizedBox(height: 4),
              for (final item in liquorItems)
                _LiquorLine(item: item, onCompletar: () => onCompletar(item)),
            ],
            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
            _SelectedTotalRow(items: selectableItems, selection: selection),
          ],
        ),
      ),
    );
  }

  /// Cronológica: bloques por hora de pedido.
  List<Widget> _buildChronological(BuildContext context) {
    final blocks = <String, List<OrderItemEntity>>{};
    for (final it in selectableItems) {
      final key = DateFormat('HH:mm', 'es_CO').format(it.orderedAt);
      blocks.putIfAbsent(key, () => []).add(it);
    }
    return [
      for (final entry in blocks.entries) ...[
        ReceiptTimeHeader(label: entry.key),
        for (final it in entry.value) _line(it),
      ],
    ];
  }

  /// Agrupada: encabezados por categoría (orden configurable) con subtotal.
  List<Widget> _buildGrouped(BuildContext context) {
    final byCat = <String, List<OrderItemEntity>>{};
    for (final it in selectableItems) {
      byCat.putIfAbsent(it.menuCategoryOrOther, () => []).add(it);
    }
    final cats = byCat.keys.toList()
      ..sort((a, b) =>
          categoryOrder.indexOf(a).compareTo(categoryOrder.indexOf(b)));
    return [
      for (final cat in cats) ...[
        ReceiptCategoryHeader(
          label: cat,
          count: byCat[cat]!.fold(0, (s, i) => s + i.quantity),
          subtotal: byCat[cat]!.fold(0, (s, i) => s + i.lineTotal),
          collapsed: collapsedCats.contains(cat),
          onToggle: () => onToggleCat(cat),
        ),
        if (!collapsedCats.contains(cat))
          for (final it in byCat[cat]!) _line(it),
      ],
    ];
  }

  Widget _line(OrderItemEntity item) => _SelectableLine(
        key: ValueKey(item.id),
        item: item,
        selected: selection.isSelected(item.id),
        onTap: () => onToggle(item),
      );
}

class _SelectableLine extends StatelessWidget {
  const _SelectableLine({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final OrderItemEntity item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: selected ? AppColors.secondaryDark : AppColors.paperInkSoft,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${item.quantity}× ${item.productName}',
                style:
                    AppTextStyles.receiptBody.copyWith(color: AppColors.paperInk),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.lineTotal.toCop,
              style: AppTextStyles.receiptBodyBold
                  .copyWith(color: AppColors.paperInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiquorLine extends StatelessWidget {
  const _LiquorLine({required this.item, required this.onCompletar});

  final OrderItemEntity item;
  final VoidCallback onCompletar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.quantity}× ${item.productName}  ${item.lineTotal.toCop}',
              style:
                  AppTextStyles.receiptBody.copyWith(color: AppColors.paperInk),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onCompletar,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: const Text('Completar'),
          ),
        ],
      ),
    );
  }
}

class _SelectedTotalRow extends StatelessWidget {
  const _SelectedTotalRow({required this.items, required this.selection});

  final List<OrderItemEntity> items;
  final BillingSelection selection;

  @override
  Widget build(BuildContext context) {
    final total = selection.subtotalOf(items);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('SELECCIONADO',
            style:
                AppTextStyles.receiptTotal.copyWith(color: AppColors.paperInk)),
        Text(total.toCop,
            style: AppTextStyles.receiptTotal
                .copyWith(color: AppColors.secondaryDark)),
      ],
    );
  }
}

// ── Barra inferior ───────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.subtotal,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onCobrar,
  });

  final int subtotal;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final VoidCallback? onCobrar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              TextButton(onPressed: onSelectAll, child: const Text('Todos')),
              TextButton(onPressed: onClearAll, child: const Text('Ninguno')),
              const Spacer(),
              Text(subtotal.toCop, style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCobrar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.point_of_sale_rounded),
              label: Text(selectedCount > 0
                  ? 'Cobrar seleccionados ($selectedCount)'
                  : 'Cobrar'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment method sheet ─────────────────────────────────────────────────────

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({
    required this.subtotal,
    required this.onSelected,
    this.onExact,
  });

  final int subtotal;
  final void Function(PaymentMethod) onSelected;
  final VoidCallback? onExact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space24,
        AppDimensions.pagePaddingH,
        AppDimensions.space32,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimensions.space16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('¿Cómo paga el cliente?', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppDimensions.space20),
            _MethodTile(
              icon: Icons.payments_rounded,
              label: 'Efectivo',
              description: 'Calcula el vuelto automáticamente.',
              color: AppColors.statusGreen,
              onTap: () => onSelected(PaymentMethod.cash),
            ),
            const SizedBox(height: AppDimensions.space12),
            _MethodTile(
              icon: Icons.smartphone_rounded,
              label: 'Transferencia',
              description: 'Foto del comprobante y listo.',
              color: AppColors.statusBlue,
              onTap: () => onSelected(PaymentMethod.transfer),
            ),
            if (onExact != null) ...[
              const SizedBox(height: AppDimensions.space12),
              _MethodTile(
                icon: Icons.check_circle_rounded,
                label: 'Pago exacto',
                description:
                    'Registra ${subtotal.toCop} en efectivo, sin escribir monto.',
                color: AppColors.primary,
                onTap: onExact!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: AppDimensions.tapTargetStd,
              height: AppDimensions.tapTargetStd,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(icon, color: color, size: AppDimensions.iconLg),
            ),
            const SizedBox(width: AppDimensions.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: AppTextStyles.labelLarge.copyWith(color: color)),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Text(
          'Error al cargar la cuenta: $error',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.statusRed),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
