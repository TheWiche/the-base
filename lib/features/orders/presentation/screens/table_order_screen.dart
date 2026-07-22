import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/settings/bar_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../../tables/domain/entities/table_session_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../providers/order_providers.dart';
import '../widgets/add_item_bottom_sheet.dart';
import '../widgets/factura_sheet.dart';
import '../widgets/receipt_view.dart';

/// Per-table order management screen — estilo tiquete de papel.
///
/// Muestra lo que ha consumido la mesa como un tiquete (bloques por hora,
/// TOTAL/pagado/SALDO), con botonera Agregar / Cobrar / Factura / Comprobante.
/// Las acciones por ítem (cancelar/repetir) se abren por toque largo.
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
    final barName = ref.watch(barNameProvider);

    return Scaffold(
      appBar: _buildAppBar(_session),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _OrderErrorBody(error: error),
              data: (items) => _session == null
                  ? const Center(child: CircularProgressIndicator())
                  : _ReceiptBody(
                      barName: barName,
                      session: _session!,
                      items: items,
                      onLongPressItem: _showItemMenu,
                    ),
            ),
          ),
          itemsAsync.maybeWhen(
            data: (items) => _ActionBar(
              sessionId: widget.sessionId,
              items: items,
              onAgregar: _openAddItem,
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
                      Text('Mesa ${session.tableNumber}',
                          style: AppTextStyles.headlineSmall),
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
                  Icon(Icons.edit_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.brand.withOpacity(0.5)
                          : AppColors.brand.withOpacity(0.6)),
                ],
              ),
            ),
      actions: [
        if (session != null)
          IconButton(
            tooltip: 'Compartir factura',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => FacturaSheet.show(context, widget.sessionId),
          ),
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
              style: AppTextStyles.statusBadge.copyWith(color: session.statusColor),
            ),
          ),
      ],
    );
  }

  // ── Item actions ────────────────────────────────────────────────────────────

  void _openAddItem() {
    AddItemBottomSheet.show(
      context: context,
      tableSessionId: widget.sessionId,
      onAdd: (params) async {
        final failure = await ref
            .read(tableOrderProvider(widget.sessionId).notifier)
            .addItem(params);
        if (failure != null && mounted) _showError(failure);
      },
    );
  }

  void _showItemMenu(OrderItemEntity item) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '${item.quantity}× ${item.productName}',
                style: AppTextStyles.titleMedium,
              ),
            ),
            if (item.isLiquor && !item.isPaid && !item.isCancelled)
              ListTile(
                leading:
                    const Icon(Icons.check_circle_rounded, color: AppColors.statusGreen),
                title: const Text('Completar botella'),
                subtitle: Text(
                  'Pagada en barra/caja — baja la deuda, no entra a tu saldo',
                  style: AppTextStyles.bodySmall,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _settleLiquor(item);
                },
              ),
            if (!item.isCancelled)
              ListTile(
                leading: const Icon(Icons.replay_rounded, color: AppColors.primary),
                title: const Text('Repetir'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _repeatItem(item);
                },
              ),
            if (!item.isCancelled && !item.isPaid)
              ListTile(
                leading: const Icon(Icons.cancel_rounded, color: AppColors.statusRed),
                title: const Text('Cancelar ítem'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _cancelItem(item);
                },
              ),
            if (item.isCancelled)
              ListTile(
                leading:
                    const Icon(Icons.delete_forever_rounded, color: AppColors.statusRed),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deleteItem(item.id);
                },
              ),
          ],
        ),
      ),
    );
  }


  Future<void> _cancelItem(OrderItemEntity item) async {
    final failure = await ref
        .read(tableOrderProvider(widget.sessionId).notifier)
        .cancelItem(item.id);
    if (!mounted) return;
    if (failure != null) {
      _showError(failure);
      return;
    }
    AppToast.success(
      context,
      'Cancelado: ${item.productName}',
      actionLabel: 'Deshacer',
      onAction: () async {
        final undoFailure = await ref
            .read(tableOrderProvider(widget.sessionId).notifier)
            .uncancelItem(item.id);
        if (undoFailure != null && mounted) _showError(undoFailure);
      },
    );
  }

  Future<void> _settleLiquor(OrderItemEntity item) async {
    final failure = await ref
        .read(tableOrderProvider(widget.sessionId).notifier)
        .settleLiquor(item.id);
    if (!mounted) return;
    if (failure != null) {
      _showError(failure);
    } else {
      _showInfo('Botella completada: ${item.productName}');
    }
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
    final nonCancelled = items.where((i) => !i.isCancelled).toList();

    if (nonCancelled.isEmpty) {
      _showInfo('No hay ítems para repetir.');
      return;
    }

    // Solo la ÚLTIMA ronda: el bloque de hora (minuto) más reciente.
    String minuteKey(DateTime d) =>
        '${d.year}-${d.month}-${d.day} ${d.hour}:${d.minute}';
    final latestOrdered = nonCancelled
        .map((i) => i.orderedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final lastKey = minuteKey(latestOrdered);
    final repeatable = nonCancelled
        .where((i) => minuteKey(i.orderedAt) == lastKey)
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.replay_rounded,
            color: AppColors.brand, size: AppDimensions.iconXl),
        title: Text('¿Repetir ronda?', style: AppTextStyles.headlineSmall),
        content: Text(
          'Se repetirá la última ronda: ${repeatable.length} '
          '${repeatable.length == 1 ? 'ítem' : 'ítems'} nuevos (pendientes).',
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

  Future<void> _showRenameDialog(TableSessionEntity session) async {
    final controller = TextEditingController(text: session.apodo ?? '');

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          icon: const Icon(Icons.label_rounded, color: AppColors.brand),
          title: Text('Apodo de la mesa', style: AppTextStyles.headlineSmall),
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
                      onPressed: () => setDialogState(() => controller.clear()),
                    )
                  : null,
            ),
            maxLength: 40,
            onChanged: (_) => setDialogState(() {}),
            onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
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
                style: TextButton.styleFrom(foregroundColor: AppColors.statusRed),
                child: const Text('Quitar'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (result == null || !mounted) return;

    final failure = await ref
        .read(tableOrderProvider(widget.sessionId).notifier)
        .renameApodo(result.isEmpty ? null : result);

    if (failure != null && mounted) _showError(failure);
  }

  void _showInfo(String message) => AppToast.success(context, message);

  void _showError(Failure failure) => AppToast.error(context, failure.message);
}

// ── Cuerpo del tiquete ──────────────────────────────────────────────────────────

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({
    required this.barName,
    required this.session,
    required this.items,
    required this.onLongPressItem,
  });

  final String barName;
  final TableSessionEntity session;
  final List<OrderItemEntity> items;
  final void Function(OrderItemEntity item) onLongPressItem;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: ReceiptPaper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReceiptHeader(
              barName: barName,
              tableNumber: session.tableNumber,
              apodo: session.apodo,
              openedAt: session.openedAt,
            ),
            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
            ReceiptChronological(items: items, onLongPressItem: onLongPressItem),
            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
            ReceiptFooter(items: items),
          ],
        ),
      ),
    );
  }
}

// ── Botonera inferior ────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.sessionId,
    required this.items,
    required this.onAgregar,
  });

  final int sessionId;
  final List<OrderItemEntity> items;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    final unpaidTotal = items
        .where((i) => !i.isCancelled && !i.isPaid)
        .fold(0, (s, i) => s + i.lineTotal);
    final allPaid = items.isNotEmpty &&
        items.where((i) => !i.isCancelled).every((i) => i.isPaid);

    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            width: 1,
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onAgregar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF241A05),
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: allPaid
                  ? () => context.go('/tables')
                  : (unpaidTotal > 0
                      ? () => context.push('/billing/$sessionId')
                      : null),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: Icon(allPaid
                  ? Icons.check_circle_rounded
                  : Icons.point_of_sale_rounded),
              label: Text(allPaid ? 'Cerrar Mesa' : 'Cobrar'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────────────

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
            const Icon(Icons.error_outline_rounded,
                color: AppColors.statusRed, size: 48),
            const SizedBox(height: AppDimensions.space12),
            Text('Error al cargar el pedido',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.statusRed)),
            const SizedBox(height: AppDimensions.space8),
            Text(error.toString(),
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
