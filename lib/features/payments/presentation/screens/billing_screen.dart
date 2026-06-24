import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../tables/domain/entities/table_session_entity.dart';
import '../../domain/entities/billing_selection.dart';
import '../../domain/entities/payment_receipt_entity.dart';
import '../../domain/entities/sub_cuenta.dart';
import '../providers/payment_providers.dart';
import '../providers/sub_cuenta_providers.dart';
import '../widgets/billing_item_tile.dart';
import '../widgets/selected_subtotal_bar.dart';

/// The main billing / checkout screen for a single table session.
///
/// Normal mode: waiter selects items and taps COBRAR → payment method sheet.
/// Split mode (sub-cuentas): items are grouped by payer; each cuenta has its
/// own COBRAR button that triggers the payment flow for just those items.
class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(tableOrderProvider(sessionId));
    final session = ref.watch(tableSessionByIdProvider(sessionId));
    final selection = ref.watch(billingSelectionProvider(sessionId));
    final subCuenta = ref.watch(subCuentaProvider(sessionId));

    return Scaffold(
      appBar: _buildAppBar(context, ref, session, subCuenta),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (items) {
          final billable = items.where((i) => !i.isCancelled).toList();
          final selectable = billable.where((i) => !i.isPaid).toList();

          if (subCuenta.isActive) {
            return _SubCuentaView(
              items: selectable,
              subCuentaState: subCuenta,
              sessionId: sessionId,
              onCobrarCuenta: (cuenta) =>
                  _showSubCuentaPaymentSheet(context, ref, cuenta, selectable),
            );
          }

          return Stack(
            children: [
              _ItemList(
                items: billable,
                selection: selection,
                sessionId: sessionId,
              ),

              // Floating gradient fade so the bottom bar doesn't cut off content.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context)
                              .scaffoldBackgroundColor
                              .withOpacity(0),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: itemsAsync.maybeWhen(
        data: (items) {
          final billable = items.where((i) => !i.isCancelled).toList();
          final selectable = billable.where((i) => !i.isPaid).toList();

          if (subCuenta.isActive) {
            return _SubCuentaBottomBar(
              cuentaCount: subCuenta.cuentas.length,
              onAddCuenta: () =>
                  ref.read(subCuentaProvider(sessionId).notifier).addCuenta(),
            );
          }

          final subtotal = selection.subtotalOf(selectable);

          return SelectedSubtotalBar(
            selection: selection,
            subtotal: subtotal,
            selectableCount: selectable.length,
            onCobrar: () => _showPaymentMethodSheet(
              context,
              ref,
              selectable: selectable,
              selection: selection,
              subtotal: subtotal,
            ),
            onSelectAll: () => ref
                .read(billingSelectionProvider(sessionId).notifier)
                .selectAll({for (final i in selectable) i.id: i.quantity}),
            onClearAll: () => ref
                .read(billingSelectionProvider(sessionId).notifier)
                .clearAll(),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    TableSessionEntity? session,
    SubCuentaState subCuenta,
  ) {
    if (subCuenta.isActive) {
      return AppBar(
        title: Text('Dividir cuenta', style: AppTextStyles.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancelar división',
          onPressed: () =>
              ref.read(subCuentaProvider(sessionId).notifier).deactivate(),
        ),
      );
    }

    return AppBar(
      title: session == null
          ? Text('Cobrar', style: AppTextStyles.headlineSmall)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cobrar — Mesa ${session.tableNumber}',
                  style: AppTextStyles.headlineSmall,
                ),
                if (session.apodo != null)
                  Text(
                    '"${session.apodo}"',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.brand,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
      actions: [
        if (session != null) ...[
          IconButton(
            icon: const Icon(Icons.call_split_rounded),
            tooltip: 'Dividir cuenta',
            onPressed: () =>
                ref.read(subCuentaProvider(sessionId).notifier).activate(),
          ),
          Container(
            margin: const EdgeInsets.only(right: AppDimensions.space16),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.badgePaddingH,
              vertical: AppDimensions.badgePaddingV,
            ),
            decoration: BoxDecoration(
              color: session.statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(color: session.statusColor.withOpacity(0.4)),
            ),
            child: Text(
              session.statusLabel.toUpperCase(),
              style: AppTextStyles.statusBadge.copyWith(
                color: session.statusColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showPaymentMethodSheet(
    BuildContext context,
    WidgetRef ref, {
    required List<OrderItemEntity> selectable,
    required BillingSelection selection,
    required int subtotal,
  }) {
    if (selection.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentMethodSheet(
        subtotal: subtotal,
        onSelected: (method) {
          Navigator.of(context).pop();
          _navigateToPayment(context, ref, method: method, subtotal: subtotal);
        },
      ),
    );
  }

  void _navigateToPayment(
    BuildContext context,
    WidgetRef ref, {
    required PaymentMethod method,
    required int subtotal,
  }) {
    final currentSelection = ref.read(billingSelectionProvider(sessionId));
    final quantities = currentSelection.selectedQuantities;

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

  void _showSubCuentaPaymentSheet(
    BuildContext context,
    WidgetRef ref,
    SubCuenta cuenta,
    List<OrderItemEntity> allUnpaid,
  ) {
    final cuentaItems = allUnpaid.where((i) => cuenta.contains(i.id)).toList();
    if (cuentaItems.isEmpty) return;
    final subtotal = cuentaItems.fold(0, (sum, i) => sum + i.lineTotal);

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentMethodSheet(
        subtotal: subtotal,
        onSelected: (method) {
          Navigator.of(context).pop();
          final args = PaymentNavigationArgs(
            sessionId: sessionId,
            selectedItemIds: cuentaItems.map((i) => i.id).toList(),
            selectedQuantities: {for (final i in cuentaItems) i.id: i.quantity},
            billSubtotal: subtotal,
          );
          final path = method == PaymentMethod.cash
              ? '/billing/$sessionId/cash'
              : '/billing/$sessionId/transfer';
          context.push(path, extra: args);
        },
      ),
    );
  }
}

// ── Item list (normal mode) ───────────────────────────────────────────────────

class _ItemList extends ConsumerWidget {
  const _ItemList({
    required this.items,
    required this.selection,
    required this.sessionId,
  });

  final List<OrderItemEntity> items;
  final BillingSelection selection;
  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unpaid = items.where((i) => !i.isPaid).toList()
      ..sort((a, b) => a.orderedAt.compareTo(b.orderedAt));
    final paid = items.where((i) => i.isPaid).toList();

    if (items.isEmpty) return const _EmptyBillingBody();

    return CustomScrollView(
      slivers: [
        if (unpaid.isNotEmpty) ...[
          _SectionHeader(
            label: 'SELECCIONAR PARA COBRAR',
            count: unpaid.length,
            color: AppColors.brand,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => BillingItemTile(
                  key: ValueKey(unpaid[i].id),
                  item: unpaid[i],
                  selection: selection,
                  onToggle: () => ref
                      .read(billingSelectionProvider(sessionId).notifier)
                      .toggle(unpaid[i].id, unpaid[i].quantity),
                  onSetQuantity: (q) => ref
                      .read(billingSelectionProvider(sessionId).notifier)
                      .setQuantity(unpaid[i].id, q),
                ),
                childCount: unpaid.length,
              ),
            ),
          ),
        ],

        if (paid.isNotEmpty) ...[
          _SectionHeader(
            label: 'YA PAGADOS',
            count: paid.length,
            color: AppColors.statusGreen,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => BillingItemTile(
                  key: ValueKey(paid[i].id),
                  item: paid[i],
                  selection: selection,
                  onToggle: () {},
                  onSetQuantity: (_) {},
                ),
                childCount: paid.length,
              ),
            ),
          ),
        ],

        const SliverPadding(padding: EdgeInsets.only(bottom: 160)),
      ],
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH,
          AppDimensions.space20,
          AppDimensions.pagePaddingH,
          AppDimensions.space8,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            Text(
              label,
              style: AppTextStyles.statusBadge.copyWith(color: color),
            ),
            const SizedBox(width: AppDimensions.space8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.statusBadge.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment method sheet ───────────────────────────────────────────────────────

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({
    required this.subtotal,
    required this.onSelected,
  });

  final int subtotal;
  final void Function(PaymentMethod) onSelected;

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
                  color:
                      isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              '¿Cómo paga el cliente?',
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
              description:
                  'Nequi, Daviplata u otro. Requiere foto del comprobante.',
              color: AppColors.statusBlue,
              onTap: () => onSelected(PaymentMethod.transfer),
            ),
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
                  Text(
                    label.toUpperCase(),
                    style: AppTextStyles.labelLarge.copyWith(color: color),
                  ),
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
            Icon(
              Icons.chevron_right_rounded,
              color: color,
              size: AppDimensions.iconMd,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyBillingBody extends StatelessWidget {
  const _EmptyBillingBody();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 80,
              color: AppColors.statusGreen.withOpacity(0.3),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              'Mesa saldada',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.statusGreen,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Todos los ítems de esta mesa han sido cobrados.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.statusRed,
              size: 48,
            ),
            const SizedBox(height: AppDimensions.space12),
            Text(
              'Error al cargar la cuenta',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.statusRed,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              error.toString(),
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-cuenta split mode
// ══════════════════════════════════════════════════════════════════════════════

/// Indexed palette for sub-cuenta color coding (up to 5 cuentas).
Color _cuentaColor(int index) {
  const colors = [
    Color(0xFF3B82F6), // blue
    Color(0xFFF97316), // orange
    Color(0xFF22C55E), // green
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // violet
  ];
  return colors[index % colors.length];
}

// ── Split view ────────────────────────────────────────────────────────────────

class _SubCuentaView extends ConsumerWidget {
  const _SubCuentaView({
    required this.items,
    required this.subCuentaState,
    required this.sessionId,
    required this.onCobrarCuenta,
  });

  final List<OrderItemEntity> items;
  final SubCuentaState subCuentaState;
  final int sessionId;
  final void Function(SubCuenta) onCobrarCuenta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assigned = subCuentaState.assignedItemIds;
    final unassigned = items.where((i) => !assigned.contains(i.id)).toList();

    // Pre-compute items per cuenta to avoid redundant filtering inside builders.
    final cuentaItems = [
      for (final c in subCuentaState.cuentas)
        items.where((i) => c.contains(i.id)).toList(),
    ];

    return CustomScrollView(
      slivers: [
        // ── Unassigned pool ───────────────────────────────────────────
        if (unassigned.isNotEmpty) ...[
          _SectionHeader(
            label: 'SIN ASIGNAR',
            count: unassigned.length,
            color: AppColors.darkOnSurfaceVariant,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _SubCuentaItemRow(
                  key: ValueKey(unassigned[i].id),
                  item: unassigned[i],
                  owner: null,
                  allCuentas: subCuentaState.cuentas,
                  onAssign: (cuentaId) => cuentaId == null
                      ? ref
                          .read(subCuentaProvider(sessionId).notifier)
                          .unassignItem(unassigned[i].id)
                      : ref
                          .read(subCuentaProvider(sessionId).notifier)
                          .assignItem(unassigned[i].id, cuentaId),
                ),
                childCount: unassigned.length,
              ),
            ),
          ),
        ],

        // ── Per-cuenta sections ───────────────────────────────────────
        for (int idx = 0; idx < subCuentaState.cuentas.length; idx++) ...[
          _SubCuentaHeader(
            cuenta: subCuentaState.cuentas[idx],
            color: _cuentaColor(idx),
            items: items,
            canRemove: subCuentaState.cuentas.length > 2,
            onRemove: () => ref
                .read(subCuentaProvider(sessionId).notifier)
                .removeCuenta(subCuentaState.cuentas[idx].id),
            onCobrar: () => onCobrarCuenta(subCuentaState.cuentas[idx]),
          ),
          if (cuentaItems[idx].isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _SubCuentaItemRow(
                    key: ValueKey(cuentaItems[idx][i].id),
                    item: cuentaItems[idx][i],
                    owner: subCuentaState.cuentas[idx],
                    allCuentas: subCuentaState.cuentas,
                    onAssign: (cuentaId) => cuentaId == null
                        ? ref
                            .read(subCuentaProvider(sessionId).notifier)
                            .unassignItem(cuentaItems[idx][i].id)
                        : ref
                            .read(subCuentaProvider(sessionId).notifier)
                            .assignItem(cuentaItems[idx][i].id, cuentaId),
                  ),
                  childCount: cuentaItems[idx].length,
                ),
              ),
            ),
        ],

        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }
}

// ── Cuenta section header ─────────────────────────────────────────────────────

class _SubCuentaHeader extends StatelessWidget {
  const _SubCuentaHeader({
    required this.cuenta,
    required this.color,
    required this.items,
    required this.canRemove,
    required this.onRemove,
    required this.onCobrar,
  });

  final SubCuenta cuenta;
  final Color color;
  final List<OrderItemEntity> items;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onCobrar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtotal = cuenta.subtotalOf(items);
    final itemCount = cuenta.itemIds.length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH,
          AppDimensions.space20,
          AppDimensions.pagePaddingH,
          AppDimensions.space8,
        ),
        child: Row(
          children: [
            // Colored stripe
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppDimensions.space8),

            // Label
            Text(
              cuenta.label.toUpperCase(),
              style: AppTextStyles.statusBadge.copyWith(color: color),
            ),
            const SizedBox(width: AppDimensions.space8),

            // Item count badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                '$itemCount',
                style: AppTextStyles.statusBadge.copyWith(color: color),
              ),
            ),

            const Spacer(),

            // Subtotal
            if (subtotal > 0) ...[
              Text(
                subtotal.toCop,
                style:
                    AppTextStyles.titleMedium.copyWith(color: color),
              ),
              const SizedBox(width: AppDimensions.space8),
            ],

            // COBRAR button
            if (itemCount > 0)
              TextButton(
                onPressed: onCobrar,
                style: TextButton.styleFrom(
                  backgroundColor: color.withOpacity(0.12),
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space12,
                    vertical: AppDimensions.space6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm),
                    side: BorderSide(color: color.withOpacity(0.4)),
                  ),
                ),
                child: Text(
                  'COBRAR',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

            // Remove cuenta
            if (canRemove) ...[
              const SizedBox(width: AppDimensions.space4),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: AppDimensions.iconSm,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Eliminar cuenta',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Item row in split mode ────────────────────────────────────────────────────

class _SubCuentaItemRow extends StatelessWidget {
  const _SubCuentaItemRow({
    super.key,
    required this.item,
    required this.owner,
    required this.allCuentas,
    required this.onAssign,
  });

  final OrderItemEntity item;
  final SubCuenta? owner;
  final List<SubCuenta> allCuentas;

  /// Called with the target cuentaId, or null to unassign.
  final void Function(int? cuentaId) onAssign;

  Color _ownerColor() {
    if (owner == null) return AppColors.darkOutline;
    final idx = allCuentas.indexWhere((c) => c.id == owner!.id);
    return _cuentaColor(idx < 0 ? 0 : idx);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _ownerColor();
    final isAssigned = owner != null;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet<void>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _AssignmentSheet(
            item: item,
            owner: owner,
            cuentas: allCuentas,
            onAssign: onAssign,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: AppDimensions.space8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space10,
        ),
        decoration: BoxDecoration(
          color: isAssigned
              ? color.withOpacity(0.06)
              : (isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isAssigned
                ? color.withOpacity(0.45)
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
            width: isAssigned
                ? AppDimensions.cardBorderWidth
                : AppDimensions.cardBorderWidth,
          ),
        ),
        child: Row(
          children: [
            // Owner color dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAssigned
                    ? color
                    : (isDark
                        ? AppColors.darkOutline
                        : AppColors.lightOutline),
              ),
            ),
            const SizedBox(width: AppDimensions.space10),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.quantity > 1
                        ? '${item.productName}  ×${item.quantity}'
                        : item.productName,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.lightOnSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.quantity > 1)
                    Text(
                      '${item.price.toCop} c/u',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            // Line total + assignment label
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.lineTotal.toCop,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: isAssigned ? color : item.categoryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      owner?.label ?? 'Sin asignar',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isAssigned
                            ? color
                            : (isDark
                                ? AppColors.darkDisabled
                                : AppColors.lightDisabled),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space4),
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 13,
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assignment bottom sheet ───────────────────────────────────────────────────

class _AssignmentSheet extends StatelessWidget {
  const _AssignmentSheet({
    required this.item,
    required this.owner,
    required this.cuentas,
    required this.onAssign,
  });

  final OrderItemEntity item;
  final SubCuenta? owner;
  final List<SubCuenta> cuentas;
  final void Function(int? cuentaId) onAssign;

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
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimensions.space16),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text('Asignar a cuenta', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppDimensions.space4),
            Text(
              item.quantity > 1
                  ? '${item.productName}  ×${item.quantity}'
                  : item.productName,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDimensions.space20),

            // Cuenta options
            for (int idx = 0; idx < cuentas.length; idx++) ...[
              _AssignmentOption(
                label: cuentas[idx].label,
                color: _cuentaColor(idx),
                isSelected: owner?.id == cuentas[idx].id,
                onTap: () {
                  Navigator.of(context).pop();
                  onAssign(cuentas[idx].id);
                },
              ),
              const SizedBox(height: AppDimensions.space8),
            ],

            // Unassign option
            _AssignmentOption(
              label: 'Sin asignar',
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
              isSelected: owner == null,
              onTap: () {
                Navigator.of(context).pop();
                onAssign(null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentOption extends StatelessWidget {
  const _AssignmentOption({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color:
                isSelected ? color.withOpacity(0.6) : color.withOpacity(0.25),
            width: isSelected ? 2.0 : AppDimensions.cardBorderWidth,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(color: color),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: color,
                size: AppDimensions.iconSm,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Split mode bottom bar ─────────────────────────────────────────────────────

class _SubCuentaBottomBar extends StatelessWidget {
  const _SubCuentaBottomBar({
    required this.cuentaCount,
    required this.onAddCuenta,
  });

  final int cuentaCount;
  final VoidCallback onAddCuenta;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH,
          AppDimensions.space12,
          AppDimensions.pagePaddingH,
          AppDimensions.space12,
        ),
        child: SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeightMd,
          child: OutlinedButton.icon(
            onPressed: cuentaCount < 5 ? onAddCuenta : null,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              cuentaCount < 5
                  ? 'AGREGAR CUENTA ($cuentaCount)'
                  : 'MÁXIMO 5 CUENTAS',
              style: AppTextStyles.labelLarge,
            ),
          ),
        ),
      ),
    );
  }
}
