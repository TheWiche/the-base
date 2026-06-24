import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../tables/domain/entities/table_session_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../providers/order_providers.dart';
import '../widgets/add_item_bottom_sheet.dart';
import '../widgets/order_item_tile.dart';

/// Per-table order management screen.
///
/// Receives [sessionId] from the router and:
///   • Streams all items for the session via [tableOrderProvider].
///   • Groups items into sections: Pending → Delivered → Paid → Cancelled.
///   • FAB opens [AddItemBottomSheet] for adding standard or liquor items.
///   • Bottom bar shows the running customer total + COBRAR CTA.
///   • Long-pressing any non-cancelled, non-paid item opens the cancel menu.
class TableOrderScreen extends ConsumerStatefulWidget {
  const TableOrderScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<TableOrderScreen> createState() => _TableOrderScreenState();
}

class _TableOrderScreenState extends ConsumerState<TableOrderScreen> {
  // Cached so "Cargando mesa..." never flashes on navigation return.
  TableSessionEntity? _session;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(tableOrderProvider(widget.sessionId));
    final sessionLive = ref.watch(tableSessionByIdProvider(widget.sessionId));
    if (sessionLive != null) _session = sessionLive;

    return Scaffold(
      appBar: _buildAppBar(_session),
      // FAB va dentro del Stack del body para que quede por encima del bar.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                itemsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _OrderErrorBody(error: error),
                  data: (items) => _OrderBody(
                    items: items,
                    onCancel: _cancelItem,
                    onRepeat: _repeatItem,
                    onDeleteCancelled: _deleteItem,
                    onClearAllCancelled: _clearCancelled,
                  ),
                ),
                Positioned(
                  right: AppDimensions.pagePaddingH,
                  bottom: AppDimensions.pagePaddingH,
                  child: FloatingActionButton.extended(
                    heroTag: 'add_item_${widget.sessionId}',
                    onPressed: () => AddItemBottomSheet.show(
                      context: context,
                      tableSessionId: widget.sessionId,
                      onAdd: (params) async {
                        final failure = await ref
                            .read(
                              tableOrderProvider(widget.sessionId).notifier,
                            )
                            .addItem(params);
                        if (failure != null && mounted) _showError(failure);
                      },
                    ),
                    backgroundColor: AppColors.brand,
                    foregroundColor: const Color(0xFF1A0A00),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      'AGREGAR',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: const Color(0xFF1A0A00),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bar de cobro pegado al fondo — en el body, no en bottomNavigationBar.
          itemsAsync.maybeWhen(
            data: (items) => _CobrarBar(
              sessionId: widget.sessionId,
              items: items,
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(TableSessionEntity? session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: session == null
          ? Text('Cargando mesa...', style: AppTextStyles.headlineSmall)
          : GestureDetector(
              onTap: () => _showRenameDialog(session),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mesa ${session.tableNumber}',
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
                  const SizedBox(width: AppDimensions.space6),
                  Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.brand.withOpacity(0.5)
                        : AppColors.brand.withOpacity(0.6),
                  ),
                ],
              ),
            ),
      actions: [
        if (session != null)
          IconButton(
            tooltip: 'Repetir ronda',
            icon: const Icon(Icons.replay_rounded),
            onPressed: _repeatRound,
          ),
        if (session != null)
          Container(
            margin: const EdgeInsets.only(right: AppDimensions.space16),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space10,
              vertical: AppDimensions.space4,
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
    );
  }

  Future<void> _cancelItem(int itemId) async {
    final failure = await ref
        .read(tableOrderProvider(widget.sessionId).notifier)
        .cancelItem(itemId);
    if (failure != null && mounted) _showError(failure);
  }

  Future<void> _repeatItem(OrderItemEntity item) async {
    final failure = await ref
        .read(tableOrderProvider(widget.sessionId).notifier)
        .repeatItems([item.toAddItemParams()]);
    if (!mounted) return;
    if (failure != null) {
      _showError(failure);
    } else {
      _showInfo('Repetido: ${item.productName}');
    }
  }

  Future<void> _repeatRound() async {
    final items =
        ref.read(tableOrderProvider(widget.sessionId)).valueOrNull ?? [];
    final repeatable = items.where((i) => !i.isCancelled).toList();

    if (repeatable.isEmpty) {
      _showInfo('No hay ítems para repetir.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.replay_rounded,
            color: AppColors.brand, size: AppDimensions.iconXl),
        title: Text('¿Repetir ronda?', style: AppTextStyles.headlineSmall),
        content: Text(
          'Se agregarán ${repeatable.length} '
          '${repeatable.length == 1 ? 'ítem' : 'ítems'} nuevos (pendientes) '
          'iguales a los actuales.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: const Color(0xFF1A0A00),
            ),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Repetir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final failure = await ref
        .read(tableOrderProvider(widget.sessionId).notifier)
        .repeatItems(repeatable.map((i) => i.toAddItemParams()).toList());
    if (!mounted) return;
    if (failure != null) {
      _showError(failure);
    } else {
      _showInfo('Ronda repetida: ${repeatable.length} ítems agregados.');
    }
  }

  Future<void> _deleteItem(int itemId) async {
    final failure = await ref
        .read(tableOrderProvider(widget.sessionId).notifier)
        .deleteItem(itemId);
    if (failure != null && mounted) _showError(failure);
  }

  Future<void> _clearCancelled() async {
    final failure = await ref
        .read(tableOrderProvider(widget.sessionId).notifier)
        .clearCancelledItems();
    if (failure != null && mounted) _showError(failure);
  }

  Future<void> _showRenameDialog(TableSessionEntity session) async {
    final controller = TextEditingController(text: session.apodo ?? '');

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          icon: const Icon(Icons.label_rounded, color: AppColors.brand),
          title: Text(
            'Apodo de la mesa',
            style: AppTextStyles.headlineSmall,
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'ej. Los cumpleañeros',
              counterText: '',
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () =>
                          setDialogState(() => controller.clear()),
                    )
                  : null,
            ),
            maxLength: 40,
            onChanged: (_) => setDialogState(() {}),
            onSubmitted: (_) =>
                Navigator.of(ctx).pop(controller.text.trim()),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar'),
            ),
            if (session.apodo != null)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(''),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.statusRed,
                ),
                child: const Text('Quitar'),
              ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(controller.text.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: const Color(0xFF1A0A00),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    // null = dialog dismissed without explicit action → no-op
    if (result == null || !mounted) return;

    final failure = await ref
        .read(tableOrderProvider(widget.sessionId).notifier)
        .renameApodo(result.isEmpty ? null : result);

    if (failure != null && mounted) _showError(failure);
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.statusGreen, size: 18),
            const SizedBox(width: AppDimensions.space8),
            Expanded(child: Text(message, style: AppTextStyles.bodyMedium)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(Failure failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure.message),
        backgroundColor: AppColors.statusRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Order body ─────────────────────────────────────────────────────────────────

class _OrderBody extends StatelessWidget {
  const _OrderBody({
    required this.items,
    required this.onCancel,
    required this.onRepeat,
    required this.onDeleteCancelled,
    required this.onClearAllCancelled,
  });

  final List<OrderItemEntity> items;
  final void Function(int itemId) onCancel;
  final void Function(OrderItemEntity item) onRepeat;
  final void Function(int itemId) onDeleteCancelled;
  final VoidCallback onClearAllCancelled;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyOrderBody();

    final pendingItems = items.where((i) => i.isActive).toList()
      ..sort((a, b) => a.orderedAt.compareTo(b.orderedAt));

    final deliveredItems = items.where((i) => i.isDelivered && !i.isPaid).toList()
      ..sort((a, b) {
        final aTime = a.deliveredAt ?? a.orderedAt;
        final bTime = b.deliveredAt ?? b.orderedAt;
        return bTime.compareTo(aTime); // newest delivered first
      });

    final paidItems = items.where((i) => i.isDelivered && i.isPaid).toList();

    final cancelledItems = items.where((i) => i.isCancelled).toList();

    return CustomScrollView(
      slivers: [
        // ── Pending ───────────────────────────────────────────────────
        if (pendingItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              label: 'PENDIENTES',
              count: pendingItems.length,
              color: AppColors.statusOrange,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => OrderItemTile(
                  key: ValueKey(pendingItems[i].id),
                  item: pendingItems[i],
                  onCancel: () => onCancel(pendingItems[i].id),
                  onRepeat: () => onRepeat(pendingItems[i]),
                ),
                childCount: pendingItems.length,
              ),
            ),
          ),
        ],

        // ── Delivered (unpaid) ────────────────────────────────────────
        if (deliveredItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              label: 'ENTREGADOS',
              count: deliveredItems.length,
              color: AppColors.statusBlue,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => OrderItemTile(
                  key: ValueKey(deliveredItems[i].id),
                  item: deliveredItems[i],
                  onCancel: () => onCancel(deliveredItems[i].id),
                  onRepeat: () => onRepeat(deliveredItems[i]),
                ),
                childCount: deliveredItems.length,
              ),
            ),
          ),
        ],

        // ── Paid (settled) ────────────────────────────────────────────
        if (paidItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              label: 'PAGADOS',
              count: paidItems.length,
              color: AppColors.statusGreen,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => OrderItemTile(
                  key: ValueKey(paidItems[i].id),
                  item: paidItems[i],
                  // Paid items are immutable — suppress the cancel gesture,
                  // but they can still be re-ordered ("otra de esa").
                  onCancel: () {},
                  onRepeat: () => onRepeat(paidItems[i]),
                ),
                childCount: paidItems.length,
              ),
            ),
          ),
        ],

        // ── Cancelled ─────────────────────────────────────────────────
        if (cancelledItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              label: 'CANCELADOS',
              count: cancelledItems.length,
              color: AppColors.statusRed,
              onClear: onClearAllCancelled,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => OrderItemTile(
                  key: ValueKey(cancelledItems[i].id),
                  item: cancelledItems[i],
                  onCancel: () {},
                  onRepeat: () {},
                  onDelete: () => onDeleteCancelled(cancelledItems[i].id),
                ),
                childCount: cancelledItems.length,
              ),
            ),
          ),
        ],

        // Espacio para que el FAB no tape el último ítem
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
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
    this.onClear,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.statusBadge.copyWith(color: color),
            ),
          ),
          if (onClear != null) ...[
            const Spacer(),
            TextButton.icon(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space8,
                  vertical: AppDimensions.space4,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
              ),
              icon: Icon(Icons.delete_sweep_rounded, size: 16, color: color),
              label: Text(
                'LIMPIAR',
                style: AppTextStyles.statusBadge.copyWith(color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── COBRAR bottom bar ──────────────────────────────────────────────────────────

class _CobrarBar extends StatelessWidget {
  const _CobrarBar({
    required this.sessionId,
    required this.items,
  });

  final int sessionId;
  final List<OrderItemEntity> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    // Only unpaid, non-cancelled items count toward what's still owed.
    final unpaidTotal = items
        .where((i) => !i.isCancelled && !i.isPaid)
        .fold(0, (sum, i) => sum + i.lineTotal);

    final pendingCount = items.where((i) => i.isActive).length;
    final allPaid = items.isNotEmpty &&
        items.where((i) => !i.isCancelled).every((i) => i.isPaid);

    final topBorderColor = allPaid
        ? AppColors.statusGreen.withOpacity(0.5)
        : (isDark ? AppColors.darkOutline : AppColors.lightOutline);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space12,
        AppDimensions.pagePaddingH,
        AppDimensions.space12 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: allPaid
            ? AppColors.statusGreen.withOpacity(0.07)
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        border: Border(
          top: BorderSide(width: 1.5, color: topBorderColor),
        ),
      ),
      child: Row(
        children: [
          // ── Running total / Cuenta saldada ───────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  allPaid ? 'CUENTA SALDADA' : 'TOTAL CUENTA',
                  style: AppTextStyles.statusBadge.copyWith(
                    color: allPaid
                        ? AppColors.statusGreen
                        : (isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 2),
                if (allPaid)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.statusGreen,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimensions.space6),
                      Text(
                        'Todos los ítems cobrados',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.statusGreen,
                        ),
                      ),
                    ],
                  )
                else ...[
                  Text(
                    unpaidTotal.toCop,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.lightOnSurface,
                    ),
                  ),
                  if (pendingCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$pendingCount ítem${pendingCount == 1 ? '' : 's'} pendiente${pendingCount == 1 ? '' : 's'}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.statusOrange,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space16),

          // ── COBRAR / Cerrar Mesa CTA ─────────────────────────────────
          // minimumSize overrides the global theme (Size.fromHeight → ∞).
          if (allPaid)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/tables'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.statusGreen,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(100, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space20,
                      vertical: AppDimensions.space10,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    'CERRAR MESA',
                    style: AppTextStyles.labelLarge.copyWith(color: Colors.black),
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                TextButton(
                  onPressed: () => context.pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.statusGreen,
                    minimumSize: const Size(60, 28),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Seguir viendo',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.statusGreen,
                    ),
                  ),
                ),
              ],
            )
          else
            FilledButton.icon(
              onPressed: unpaidTotal > 0
                  ? () => context.push('/billing/$sessionId')
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size(100, 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space24,
                  vertical: AppDimensions.space12,
                ),
              ),
              icon: const Icon(Icons.point_of_sale_rounded),
              label: Text(
                'COBRAR',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty order state ──────────────────────────────────────────────────────────

class _EmptyOrderBody extends StatelessWidget {
  const _EmptyOrderBody();

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
              color: AppColors.brand.withOpacity(0.3),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              'Mesa vacía',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Usa el botón + para agregar el primer ítem al pedido.',
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

class _OrderErrorBody extends StatelessWidget {
  const _OrderErrorBody({required this.error});

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
              'Error al cargar el pedido',
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
