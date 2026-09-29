import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Pantalla de Cobro — estilo tiquete.
///
/// Soporta:
/// 1. Cobro selectivo de ítems específicos.
/// 2. Abonos por valor numérico libre/arbitrario al saldo pendiente de la mesa.
/// 3. Cobros mixtos (Efectivo + Transferencia simultáneos).
/// 4. Liquidación normal de botellas de licores y vinos integradas en la cuenta común.
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  TableSessionEntity? _session;

  /// 0 = cronológica (bloques por hora) · 1 = agrupada (por categoría).
  int _mode = 0;

  /// Categorías plegadas en la vista agrupada.
  final _collapsedCats = <String>{};

  int get sessionId => widget.sessionId;

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
    final finSummary = ref.watch(tableFinancialSummaryProvider(sessionId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(tableOrderProvider(sessionId), (_, next) {
      next.whenData(_maybeAutoPop);
    });
    itemsAsync.whenData(_maybeAutoPop);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _session == null ? 'Cobrar' : 'Cobrar — Mesa ${_session!.tableNumber}',
          style: AppTextStyles.headlineSmall,
        ),
        actions: [
          IconButton(
            tooltip: 'Abono libre',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => _showArbitraryAmountModal(finSummary.pendingBalance),
          ),
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
          // Todas las botellas e ítems estándar se cobran juntos en la cuenta común
          final selectableItems = unpaid
            ..sort((a, b) => a.orderedAt.compareTo(b.orderedAt));

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
                  selection: selection,
                  finSummary: finSummary,
                  collapsedCats: _collapsedCats,
                  onToggleCat: (cat) => setState(() {
                    _collapsedCats.contains(cat)
                        ? _collapsedCats.remove(cat)
                        : _collapsedCats.add(cat);
                  }),
                  onToggle: (item) => ref
                      .read(billingSelectionProvider(sessionId).notifier)
                      .toggle(item.id, item.quantity),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: itemsAsync.maybeWhen(
        data: (items) {
          final selectable =
              items.where((i) => !i.isCancelled && !i.isPaid).toList();
          final subtotal = selection.subtotalOf(selectable);

          return _BottomBar(
            subtotal: subtotal,
            selectedCount: selection.count,
            pendingBalance: finSummary.pendingBalance,
            onSelectAll: () => ref
                .read(billingSelectionProvider(sessionId).notifier)
                .selectAll({for (final i in selectable) i.id: i.quantity}),
            onClearAll: () => ref
                .read(billingSelectionProvider(sessionId).notifier)
                .clearAll(),
            onAbonarLibre: () =>
                _showArbitraryAmountModal(finSummary.pendingBalance),
            onCobrar: subtotal > 0
                ? () => _showPaymentMethodSheet(
                      subtotal: subtotal,
                      isGeneralAdvance: false,
                    )
                : (finSummary.pendingBalance > 0
                    ? () => _showPaymentMethodSheet(
                          subtotal: finSummary.pendingBalance,
                          isGeneralAdvance: true,
                        )
                    : null),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  // ── Modal de Abono Libre por Valor Arbitrario ───────────────────────────────

  void _showArbitraryAmountModal(int defaultBalance) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ArbitraryAmountSheet(
        pendingBalance: defaultBalance,
        onAmountConfirmed: (amount) {
          Navigator.of(ctx).pop();
          _showPaymentMethodSheet(subtotal: amount, isGeneralAdvance: true);
        },
      ),
    );
  }

  // ── Payment method sheet ─────────────────────────────────────────────────────

  void _showPaymentMethodSheet({
    required int subtotal,
    required bool isGeneralAdvance,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentMethodSheet(
        subtotal: subtotal,
        isGeneralAdvance: isGeneralAdvance,
        onSelected: (method) {
          Navigator.of(context).pop();
          _navigateToPayment(
            method: method,
            subtotal: subtotal,
            isGeneralAdvance: isGeneralAdvance,
          );
        },
        onExact: () {
          Navigator.of(context).pop();
          _recordExactCash(
            subtotal: subtotal,
            isGeneralAdvance: isGeneralAdvance,
          );
        },
      ),
    );
  }

  void _navigateToPayment({
    required PaymentMethod method,
    required int subtotal,
    required bool isGeneralAdvance,
  }) {
    final selection = ref.read(billingSelectionProvider(sessionId));
    final quantities =
        isGeneralAdvance ? <int, int>{} : selection.selectedQuantities;
    final args = PaymentNavigationArgs(
      sessionId: sessionId,
      selectedItemIds: isGeneralAdvance ? const [] : quantities.keys.toList(),
      selectedQuantities: quantities,
      billSubtotal: subtotal,
      isGeneralAdvance: isGeneralAdvance,
    );
    final path = method == PaymentMethod.cash
        ? '/billing/$sessionId/cash'
        : '/billing/$sessionId/transfer';
    context.push(path, extra: args);
  }

  /// Pago exacto: efectivo por el total sin escribir monto.
  Future<void> _recordExactCash({
    required int subtotal,
    required bool isGeneralAdvance,
  }) async {
    final selection = ref.read(billingSelectionProvider(sessionId));
    final quantities =
        isGeneralAdvance ? <int, int>{} : selection.selectedQuantities;

    final params = RecordPaymentParams(
      tableSessionId: sessionId,
      selectedItemIds: isGeneralAdvance ? const [] : quantities.keys.toList(),
      selectedQuantities: quantities,
      amountPaid: subtotal,
      billSubtotal: subtotal,
      paymentMethod: PaymentMethod.cash,
      isGeneralAdvance: isGeneralAdvance,
    );
    final failure =
        await ref.read(paymentNotifierProvider.notifier).recordPayment(params);
    if (!mounted) return;
    if (failure != null) {
      AppToast.error(context, failure.message);
      return;
    }
    if (!isGeneralAdvance) {
      ref.read(billingSelectionProvider(sessionId).notifier).clearAll();
    }
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
    required this.selection,
    required this.finSummary,
    required this.collapsedCats,
    required this.onToggleCat,
    required this.onToggle,
  });

  final String barName;
  final TableSessionEntity? session;
  final bool grouped;
  final CategoryOrderNotifier categoryOrder;
  final List<OrderItemEntity> selectableItems;
  final BillingSelection selection;
  final TableFinancialSummary finSummary;
  final Set<String> collapsedCats;
  final void Function(String) onToggleCat;
  final void Function(OrderItemEntity) onToggle;

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

            // Resumen de abonos si ya hay pagos previos
            if (finSummary.totalPaid > 0) ...[
              const DashedDivider(padding: EdgeInsets.symmetric(vertical: 8)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Consumos',
                            style: AppTextStyles.receiptSmall
                                .copyWith(color: AppColors.paperInk)),
                        Text(finSummary.totalAccount.toCop,
                            style: AppTextStyles.receiptSmallBold
                                .copyWith(color: AppColors.paperInk)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Abonos Recibidos',
                            style: AppTextStyles.receiptSmall
                                .copyWith(color: AppColors.secondaryDark)),
                        Text('− ${finSummary.totalPaid.toCop}',
                            style: AppTextStyles.receiptSmallBold
                                .copyWith(color: AppColors.secondaryDark)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saldo Pendiente',
                            style: AppTextStyles.receiptBodyBold
                                .copyWith(color: AppColors.paperInk)),
                        Text(finSummary.pendingBalance.toCop,
                            style: AppTextStyles.receiptBodyBold
                                .copyWith(color: AppColors.statusOrange)),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
            Text(
              'TOCA PARA SELECCIONAR ÍTEMS',
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
                  finSummary.pendingBalance == 0
                      ? 'Cuenta saldada en su totalidad.'
                      : 'Todos los ítems están saldados.',
                  style: AppTextStyles.receiptBody
                      .copyWith(color: AppColors.paperInkSoft),
                  textAlign: TextAlign.center,
                ),
              ),
            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
            _SelectedTotalRow(items: selectableItems, selection: selection),
          ],
        ),
      ),
    );
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 18,
                color: selected ? AppColors.secondaryDark : AppColors.paperInkSoft,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}× ${item.productName}',
                    style:
                        AppTextStyles.receiptBody.copyWith(color: AppColors.paperInk),
                  ),
                  if (item.note != null && item.note!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '↳ ${item.note!.trim()}',
                        style: AppTextStyles.receiptSmall.copyWith(
                          color: AppColors.statusOrange,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
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
    required this.pendingBalance,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onAbonarLibre,
    required this.onCobrar,
  });

  final int subtotal;
  final int selectedCount;
  final int pendingBalance;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final VoidCallback onAbonarLibre;
  final VoidCallback? onCobrar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    final targetAmount = selectedCount > 0 ? subtotal : pendingBalance;

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
              TextButton(
                onPressed: onSelectAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Todos'),
              ),
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Ninguno'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAbonarLibre,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Abono Libre'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedCount > 0 ? 'Selección:' : 'Saldo pendiente:',
                style: AppTextStyles.labelMedium,
              ),
              Text(
                targetAmount.toCop,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.statusGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              label: Text(
                selectedCount > 0
                    ? 'Cobrar seleccionados ($selectedCount)'
                    : (pendingBalance > 0
                        ? 'Cobrar saldo pendiente (${pendingBalance.toCop})'
                        : 'Cuenta saldada'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet de Abono Arbitrario ─────────────────────────────────────────────────

class _ArbitraryAmountSheet extends StatefulWidget {
  const _ArbitraryAmountSheet({
    required this.pendingBalance,
    required this.onAmountConfirmed,
  });

  final int pendingBalance;
  final void Function(int) onAmountConfirmed;

  @override
  State<_ArbitraryAmountSheet> createState() => _ArbitraryAmountSheetState();
}

class _ArbitraryAmountSheetState extends State<_ArbitraryAmountSheet> {
  final _amountController = TextEditingController();
  int _amount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.pendingBalance > 0) {
      _setAmount(widget.pendingBalance);
    }
  }

  void _setAmount(int val) {
    _amount = val;
    _amountController.text = _formatNumber(val);
    setState(() {});
  }

  String _formatNumber(int val) {
    if (val == 0) return '0';
    final str = val.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space20,
        AppDimensions.pagePaddingH,
        AppDimensions.space24 + bottomInset,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Text('Abonar Monto Libre', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Ingresa cualquier valor arbitrario a abonar a la mesa.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.space16),

            // Chips de montos rápidos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.pendingBalance > 0)
                  ActionChip(
                    label: Text('Total (${widget.pendingBalance.toCop})'),
                    avatar: const Icon(Icons.all_inclusive_rounded, size: 16),
                    onPressed: () => _setAmount(widget.pendingBalance),
                  ),
                ActionChip(
                  label: const Text('\$10.000'),
                  onPressed: () => _setAmount(10000),
                ),
                ActionChip(
                  label: const Text('\$20.000'),
                  onPressed: () => _setAmount(20000),
                ),
                ActionChip(
                  label: const Text('\$50.000'),
                  onPressed: () => _setAmount(50000),
                ),
                ActionChip(
                  label: const Text('\$100.000'),
                  onPressed: () => _setAmount(100000),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),

            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorFormatter(),
              ],
              style: AppTextStyles.displaySmall,
              decoration: InputDecoration(
                prefixText: '\$ ',
                hintText: '0',
                filled: true,
                fillColor: AppColors.statusGreen.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide:
                      BorderSide(color: AppColors.statusGreen.withOpacity(0.4)),
                ),
              ),
              onChanged: (raw) {
                final digits = raw.replaceAll('.', '');
                setState(() {
                  _amount = int.tryParse(digits) ?? 0;
                });
              },
            ),
            const SizedBox(height: AppDimensions.space20),

            FilledButton.icon(
              onPressed: _amount > 0 ? () => widget.onAmountConfirmed(_amount) : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _amount > 0 ? 'Continuar con ${_amount.toCop}' : 'Ingresa un monto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment method sheet ─────────────────────────────────────────────────────

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({
    required this.subtotal,
    required this.isGeneralAdvance,
    required this.onSelected,
    this.onExact,
  });

  final int subtotal;
  final bool isGeneralAdvance;
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
            Text(
              isGeneralAdvance ? 'Abonar ${subtotal.toCop}' : '¿Cómo paga el cliente?',
              style: AppTextStyles.headlineSmall,
            ),
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

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final digits = newValue.text.replaceAll('.', '');
    final val = int.tryParse(digits);
    if (val == null) return oldValue;

    final str = digits;
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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
