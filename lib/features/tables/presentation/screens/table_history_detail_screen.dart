import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/settings/bar_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/master_ticket_view.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../payments/domain/entities/payment_receipt_entity.dart';
import '../../../payments/presentation/providers/payment_providers.dart';
import '../../domain/entities/table_session_entity.dart';

enum HistoryDetailMode {
  agrupado,
  cronologico,
}

/// Visor inmutable de SOLO LECTURA para cuentas cerradas ([TableStatus.closed]).
///
/// Dispone de:
/// 1. Interruptor toggle superior para alternar entre:
///    • Modo Agrupado: Consolidado de productos, métodos de pago y código de factura.
///    • Modo Cronológico: Línea de tiempo paso a paso con hora/minuto exacto de cada evento.
/// 2. Opción explícita en menú superior "Reabrir mesa" por si hubo un error de cobro,
///    sin estorbar la lectura ni sugerir reactivación innecesaria.
class TableHistoryDetailScreen extends ConsumerStatefulWidget {
  const TableHistoryDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<TableHistoryDetailScreen> createState() =>
      _TableHistoryDetailScreenState();
}

class _TableHistoryDetailScreenState
    extends ConsumerState<TableHistoryDetailScreen> {
  TableSessionEntity? _session;
  HistoryDetailMode _viewMode = HistoryDetailMode.agrupado;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionByIdProvider(widget.sessionId));
    final itemsAsync = ref.watch(tableOrderProvider(widget.sessionId));
    final paymentsAsync = ref.watch(sessionPaymentsProvider(widget.sessionId));
    final barName = ref.watch(barNameProvider);

    final sessionLive = sessionAsync.valueOrNull;
    if (sessionLive != null) _session = sessionLive;
    final currentSession = _session ?? sessionLive;

    final payments = paymentsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: _buildAppBar(currentSession),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Toggle superior para alternar vista ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePaddingH,
              AppDimensions.space8,
              AppDimensions.pagePaddingH,
              AppDimensions.space8,
            ),
            child: _HistoryModeToggle(
              currentMode: _viewMode,
              onModeChanged: (mode) {
                setState(() => _viewMode = mode);
              },
            ),
          ),

          // ── Contenido del tiquete inmutable ─────────────────────────
          Expanded(
            child: itemsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error al cargar el detalle.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.statusRed),
                ),
              ),
              data: (items) {
                if (items.isEmpty && currentSession == null) {
                  return const _EmptyBody();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  child: MasterTicketView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (currentSession != null)
                          _HistoryReceiptHeader(
                            barName: barName,
                            session: currentSession,
                          ),
                        const DashedDivider(
                            padding: EdgeInsets.symmetric(vertical: 10)),

                        if (_viewMode == HistoryDetailMode.agrupado)
                          _AgrupadoHistoryView(
                            session: currentSession,
                            items: items,
                            payments: payments,
                          )
                        else
                          _CronologicoHistoryView(
                            session: currentSession,
                            items: items,
                            payments: payments,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(TableSessionEntity? session) {
    return AppBar(
      title: session == null
          ? Text('Historial', style: AppTextStyles.headlineSmall)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mesa ${session.tableNumber}',
                  style: AppTextStyles.headlineSmall,
                ),
                if (session.apodo != null && session.apodo!.isNotEmpty)
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space10,
              vertical: AppDimensions.space4,
            ),
            decoration: BoxDecoration(
              color: AppColors.statusGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: AppColors.statusGreen.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 12, color: AppColors.statusGreen),
                const SizedBox(width: 4),
                Text(
                  'CERRADA',
                  style: AppTextStyles.statusBadge.copyWith(
                    color: AppColors.statusGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Opciones',
            onSelected: (val) {
              if (val == 'reopen') _reopenTable(session);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'reopen',
                child: Row(
                  children: [
                    Icon(Icons.restore_rounded,
                        color: AppColors.brand, size: 18),
                    SizedBox(width: 8),
                    Text('Reabrir mesa (error de cobro)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _reopenTable(TableSessionEntity session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.restore_rounded,
          color: AppColors.brand,
          size: AppDimensions.iconXl,
        ),
        title: Text('¿Reabrir mesa ${session.tableNumber}?',
            style: AppTextStyles.headlineSmall),
        content: Text(
          'Use esta función solo si hubo un error en los pedidos o en el cobro. '
          'La mesa volverá a estar abierta con sus pedidos y pagos calculados.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: const Color(0xFF1A0A00),
            ),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('REABRIR MESA'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(orderRepositoryProvider)
        .reactivateSession(session.id);

    if (!mounted) return;

    if (result case Err(:final failure)) {
      AppToast.error(context, failure.message);
    } else {
      AppToast.success(context, 'Mesa reabierta correctamente');
      context.go('/tables');
    }
  }
}

// ── Selector toggle de modo (Agrupado vs. Cronológico) ─────────────────────────

class _HistoryModeToggle extends StatelessWidget {
  const _HistoryModeToggle({
    required this.currentMode,
    required this.onModeChanged,
  });

  final HistoryDetailMode currentMode;
  final ValueChanged<HistoryDetailMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E28) : const Color(0xFFE8E8EE),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              title: 'Modo Agrupado',
              icon: Icons.receipt_long_rounded,
              isSelected: currentMode == HistoryDetailMode.agrupado,
              isDark: isDark,
              onTap: () => onModeChanged(HistoryDetailMode.agrupado),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildButton(
              title: 'Modo Cronológico',
              icon: Icons.history_toggle_off_rounded,
              isSelected: currentMode == HistoryDetailMode.cronologico,
              isDark: isDark,
              onTap: () => onModeChanged(HistoryDetailMode.cronologico),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bg = isSelected
        ? AppColors.primary
        : Colors.transparent;
    final fg = isSelected
        ? AppColors.onPrimary
        : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Encabezado de recibo de historial ─────────────────────────────────────────

class _HistoryReceiptHeader extends StatelessWidget {
  const _HistoryReceiptHeader({
    required this.barName,
    required this.session,
  });

  final String barName;
  final TableSessionEntity session;

  @override
  Widget build(BuildContext context) {
    final openedStr = DateFormat('dd/MM/yyyy · HH:mm', 'es_CO').format(session.openedAt);
    final closedStr = session.closedAt != null
        ? DateFormat('HH:mm', 'es_CO').format(session.closedAt!)
        : '—';

    return Column(
      children: [
        Text(
          barName.toUpperCase(),
          style: AppTextStyles.receiptTitle.copyWith(color: Theme.of(context).colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'MESA ${session.tableNumber}${session.apodo != null ? ' · "${session.apodo}"' : ''}',
          style: AppTextStyles.receiptBodyBold.copyWith(color: Theme.of(context).colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          'Apertura: $openedStr  |  Cierre: $closedStr',
          style: AppTextStyles.receiptSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        if (session.verificationCode != null && session.verificationCode!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.paperLine.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.paperLine),
            ),
            child: Text(
              'FACTURA: ${session.verificationCode}',
              style: AppTextStyles.receiptBodyBold.copyWith(
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Modo Agrupado: Consolidado + Métodos de pago + Factura ─────────────────────

class _AgrupadoHistoryView extends StatelessWidget {
  const _AgrupadoHistoryView({
    required this.session,
    required this.items,
    required this.payments,
  });

  final TableSessionEntity? session;
  final List<OrderItemEntity> items;
  final List<PaymentReceiptEntity> payments;

  @override
  Widget build(BuildContext context) {
    final activeItems = items.where((i) => !i.isCancelled).toList();
    final cancelledItems = items.where((i) => i.isCancelled).toList();

    final totalBill = activeItems.fold<int>(0, (s, i) => s + i.lineTotal);

    // Consolidación de productos idénticos
    final Map<String, ({String name, String? note, int quantity, int lineTotal, int unitPrice})> consolidated = {};
    for (final it in activeItems) {
      final key = '${it.productName}|||${it.note ?? ""}';
      if (!consolidated.containsKey(key)) {
        consolidated[key] = (
          name: it.productName,
          note: it.note,
          quantity: it.quantity,
          lineTotal: it.lineTotal,
          unitPrice: it.price,
        );
      } else {
        final prev = consolidated[key]!;
        consolidated[key] = (
          name: prev.name,
          note: prev.note,
          quantity: prev.quantity + it.quantity,
          lineTotal: prev.lineTotal + it.lineTotal,
          unitPrice: prev.unitPrice,
        );
      }
    }

    // Totales por método de pago
    final cashTotal = payments
        .where((p) => p.paymentMethod == PaymentMethod.cash)
        .fold<int>(0, (s, p) => s + p.netReceived);

    final transferPayments = payments
        .where((p) => p.paymentMethod == PaymentMethod.transfer)
        .toList();
    final transferTotal =
        transferPayments.fold<int>(0, (s, p) => s + p.netReceived);

    final totalPaid = payments.fold<int>(0, (s, p) => s + p.netReceived);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Productos consolidados ──────────────────────────────────
        Text(
          'PRODUCTOS CONSUMIDOS',
          style: AppTextStyles.receiptSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),

        for (final item in consolidated.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.quantity}× ${item.name}',
                        style: AppTextStyles.receiptBody.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.note != null && item.note!.isNotEmpty)
                        Text(
                          '↳ ${item.note}',
                          style: AppTextStyles.receiptSmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  item.lineTotal.toCop,
                  style: AppTextStyles.receiptBodyBold.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

        // ── Cancelados (si hubo) ────────────────────────────────────
        if (cancelledItems.isNotEmpty) ...[
          const DashedDivider(padding: EdgeInsets.symmetric(vertical: 8)),
          Text(
            'CANCELADOS (${cancelledItems.length})',
            style: AppTextStyles.receiptSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.statusRed,
            ),
          ),
          const SizedBox(height: 4),
          for (final c in cancelledItems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${c.quantity}× ${c.productName}',
                      style: AppTextStyles.receiptSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                  Text(
                    c.lineTotal.toCop,
                    style: AppTextStyles.receiptSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
        ],

        const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),

        // ── Total de la cuenta ──────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL CUENTA',
              style: AppTextStyles.receiptTitle.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            Text(
              totalBill.toCop,
              style: AppTextStyles.receiptTitle.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
          ],
        ),

        const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),

        // ── Métodos de pago utilizados ──────────────────────────────
        Text(
          'MÉTODOS DE PAGO UTILIZADOS',
          style: AppTextStyles.receiptSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),

        if (cashTotal > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Efectivo:',
                    style: AppTextStyles.receiptBody
                        .copyWith(color: Theme.of(context).colorScheme.onSurface)),
                Text(cashTotal.toCop,
                    style: AppTextStyles.receiptBodyBold
                        .copyWith(color: AppColors.statusGreen)),
              ],
            ),
          ),

        if (transferTotal > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transferencias:',
                    style: AppTextStyles.receiptBody
                        .copyWith(color: Theme.of(context).colorScheme.onSurface)),
                Text(transferTotal.toCop,
                    style: AppTextStyles.receiptBodyBold
                        .copyWith(color: AppColors.statusBlue)),
              ],
            ),
          ),
          for (final tp in transferPayments)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 1, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '↳ ${tp.transferMethod != null ? tp.transferMethod!.displayLabel : "Transferencia"}',
                    style: AppTextStyles.receiptSmall
                        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    tp.netReceived.toCop,
                    style: AppTextStyles.receiptSmall
                        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
        ],

        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No se registraron recibos de pago detallados.',
              style: AppTextStyles.receiptSmall
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),

        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Pagado:',
                style: AppTextStyles.receiptBodyBold
                    .copyWith(color: Theme.of(context).colorScheme.onSurface)),
            Text(totalPaid.toCop,
                style: AppTextStyles.receiptBodyBold
                    .copyWith(color: AppColors.statusGreen)),
          ],
        ),

        const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),

        // ── Pie con mensaje legal / de auditoría ─────────────────────
        Center(
          child: Column(
            children: [
              Text(
                'CUENTA CERRADA Y LIQUIDADA',
                style: AppTextStyles.receiptSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.statusGreen,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Visor inmutable para auditoría del mesero',
                style: AppTextStyles.receiptSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Modo Cronológico: Línea de tiempo de eventos paso a paso ─────────────────

sealed class _TimelineEvent {
  DateTime get timestamp;
}

class _AperturaEvent extends _TimelineEvent {
  _AperturaEvent({required this.timestamp, required this.tableNumber, this.apodo});
  @override
  final DateTime timestamp;
  final int tableNumber;
  final String? apodo;
}

class _ItemAddedEvent extends _TimelineEvent {
  _ItemAddedEvent({required this.item});
  final OrderItemEntity item;
  @override
  DateTime get timestamp => item.orderedAt;
}

class _ItemCancelledEvent extends _TimelineEvent {
  _ItemCancelledEvent({required this.item});
  final OrderItemEntity item;
  @override
  DateTime get timestamp => item.orderedAt;
}

class _PaymentEvent extends _TimelineEvent {
  _PaymentEvent({required this.payment});
  final PaymentReceiptEntity payment;
  @override
  DateTime get timestamp => payment.paidAt;
}

class _CierreEvent extends _TimelineEvent {
  _CierreEvent({required this.timestamp, this.code});
  @override
  final DateTime timestamp;
  final String? code;
}

class _CronologicoHistoryView extends StatelessWidget {
  const _CronologicoHistoryView({
    required this.session,
    required this.items,
    required this.payments,
  });

  final TableSessionEntity? session;
  final List<OrderItemEntity> items;
  final List<PaymentReceiptEntity> payments;

  @override
  Widget build(BuildContext context) {
    final events = <_TimelineEvent>[];

    if (session != null) {
      events.add(_AperturaEvent(
        timestamp: session!.openedAt,
        tableNumber: session!.tableNumber,
        apodo: session!.apodo,
      ));
    }

    for (final it in items) {
      if (it.isCancelled) {
        events.add(_ItemCancelledEvent(item: it));
      } else {
        events.add(_ItemAddedEvent(item: it));
      }
    }

    for (final p in payments) {
      events.add(_PaymentEvent(payment: p));
    }

    if (session?.closedAt != null) {
      events.add(_CierreEvent(
        timestamp: session!.closedAt!,
        code: session!.verificationCode,
      ));
    }

    // Ordenar cronológicamente ascendente
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final timeFormat = DateFormat('HH:mm', 'es_CO');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'LÍNEA DE TIEMPO (EVENTOS PASO A PASO)',
          style: AppTextStyles.receiptSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        for (int i = 0; i < events.length; i++)
          _buildTimelineRow(context, events[i], timeFormat, isLast: i == events.length - 1),
      ],
    );
  }

  Widget _buildTimelineRow(
    BuildContext context,
    _TimelineEvent event,
    DateFormat timeFormat, {
    required bool isLast,
  }) {
    final timeStr = timeFormat.format(event.timestamp);

    final (IconData icon, Color iconColor, String title, String? subtitle, String? amount) = switch (event) {
      _AperturaEvent(:final tableNumber, :final apodo) => (
          Icons.door_front_door_outlined,
          AppColors.primary,
          'Apertura de Mesa $tableNumber',
          apodo != null && apodo.isNotEmpty ? '"$apodo"' : null,
          null,
        ),
      _ItemAddedEvent(:final item) => (
          Icons.add_shopping_cart_rounded,
          Theme.of(context).colorScheme.onSurface,
          '${item.quantity}× ${item.productName}',
          item.note != null && item.note!.isNotEmpty ? '↳ ${item.note}' : null,
          item.lineTotal.toCop,
        ),
      _ItemCancelledEvent(:final item) => (
          Icons.cancel_outlined,
          AppColors.statusRed,
          'Cancelado: ${item.quantity}× ${item.productName}',
          null,
          '-${item.lineTotal.toCop}',
        ),
      _PaymentEvent(:final payment) => (
          payment.paymentMethod == PaymentMethod.transfer
              ? Icons.smartphone_rounded
              : Icons.payments_rounded,
          AppColors.statusGreen,
          payment.isGeneralAdvance ? 'Abono Parcial' : 'Pago',
          '${payment.paymentMethod == PaymentMethod.transfer ? (payment.transferMethod != null ? payment.transferMethod!.displayLabel : "Transferencia") : "Efectivo"}${payment.verificationCode != null ? " · Recibo: ${payment.verificationCode}" : ""}',
          payment.netReceived.toCop,
        ),
      _CierreEvent(:final code) => (
          Icons.check_circle_rounded,
          AppColors.statusGreen,
          'Cierre de Mesa y Liquidación',
          code != null && code.isNotEmpty ? 'Factura: $code' : null,
          null,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hora
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.paperLine.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              timeStr,
              style: AppTextStyles.receiptSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Ícono
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),

          // Descripción y subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.receiptBody.copyWith(
                    fontWeight: FontWeight.w600,
                    color: event is _ItemCancelledEvent
                        ? AppColors.statusRed
                        : Theme.of(context).colorScheme.onSurface,
                    decoration: event is _ItemCancelledEvent
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTextStyles.receiptSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          // Monto
          if (amount != null)
            Text(
              amount,
              style: AppTextStyles.receiptBodyBold.copyWith(
                color: event is _ItemCancelledEvent
                    ? AppColors.statusRed
                    : (event is _PaymentEvent
                        ? AppColors.statusGreen
                        : Theme.of(context).colorScheme.onSurface),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Sin información registrada en esta cuenta.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkDisabled
              : AppColors.lightDisabled,
        ),
      ),
    );
  }
}

