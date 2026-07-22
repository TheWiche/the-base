import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/services/table_counter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../../../core/widgets/stagger_entrance.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../domain/entities/table_session_entity.dart';

enum _TableFilter { all, open, partiallyPaid }

/// Grid of active table sessions.
///
/// ── Layout ────────────────────────────────────────────────────────────────────
/// 2-column grid of [_TableCard] widgets, one per active [TableSessionEntity].
/// The FAB opens [_NewTableDialog] to create a new session.
/// Tapping a card navigates to the per-session [TableOrderScreen].
///
/// ── Reactivity ───────────────────────────────────────────────────────────────
/// Driven by [activeSessionsProvider], which fires on every Isar write that
/// touches [TableSession] — additions, status changes, and closures.
/// A 60-second periodic timer forces a setState so the elapsed-time labels
/// stay fresh between Isar events.
class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  Timer? _refreshTimer;
  _TableFilter _filter = _TableFilter.all;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) { if (mounted) setState(() {}); },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<TableSessionEntity> _applyFilter(List<TableSessionEntity> sessions) {
    return switch (_filter) {
      _TableFilter.all => sessions,
      _TableFilter.open =>
        sessions.where((s) => s.status == TableStatus.open).toList(),
      _TableFilter.partiallyPaid =>
        sessions.where((s) => s.status == TableStatus.partiallyPaid).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(activeSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesas', style: AppTextStyles.headlineSmall),
        actions: [
          IconButton(
            onPressed: () => context.push('/tables/historial'),
            tooltip: 'Historial de mesas',
            icon: const Icon(Icons.history_rounded),
            color: AppColors.brand,
          ),
          // Acceso claro al Menú: botón con etiqueta, no un ícono suelto.
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space12),
            child: FilledButton.tonalIcon(
              onPressed: () => context.push('/products'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
              label: Text('Menú', style: AppTextStyles.labelMedium),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTableDialog(context),
        icon: const Icon(Icons.table_restaurant_rounded),
        label: const Text('Nueva Mesa'),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (sessions) {
          if (sessions.isEmpty) {
            return _EmptyState(onNewTable: () => _showNewTableDialog(context));
          }
          final filtered = _applyFilter(sessions);
          return Column(
            children: [
              _FilterBar(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
                openCount: sessions.where((s) => s.status == TableStatus.open).length,
                partialCount: sessions.where((s) => s.status == TableStatus.partiallyPaid).length,
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyFilterState()
                    : _SessionsGrid(
                        sessions: filtered,
                        onTap: (s) => context.push('/tables/${s.id}/orders'),
                        onLongPress: _onTableLongPress,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onTableLongPress(TableSessionEntity session) {
    HapticFeedback.mediumImpact();
    _showDeleteTableDialog(session);
  }

  Future<void> _showDeleteTableDialog(TableSessionEntity session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever_rounded,
          color: AppColors.statusRed,
          size: AppDimensions.iconXl,
        ),
        title: Text('¿Eliminar mesa?', style: AppTextStyles.headlineSmall),
        content: Text(
          session.apodo != null
              ? 'Mesa ${session.tableNumber} — "${session.apodo}"\n\nSolo se pueden eliminar mesas sin ítems activos o pagados.'
              : 'Mesa ${session.tableNumber}\n\nSolo se pueden eliminar mesas sin ítems activos o pagados.',
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
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(orderRepositoryProvider)
        .deleteSession(session.id);

    if (!mounted) return;

    if (result case Err(:final failure)) {
      AppToast.error(context, failure.message);
    } else {
      AppToast.success(context, 'Mesa ${session.tableNumber} eliminada.');
    }
  }

  Future<void> _showNewTableDialog(BuildContext context) async {
    final counter = TableCounterService();

    // Preview the next number without committing it yet.
    final previewNumber = await counter.peekNextTableNumber();

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (_) => _NewTableDialog(
        tableNumber: previewNumber,
        onOpen: (apodo) async {
          // Commit the counter only when the user confirms.
          final assignedNumber = await counter.nextTableNumber();
          final result = await ref
              .read(openTableUseCaseProvider)
              .call(tableNumber: assignedNumber, apodo: apodo);
          if (!mounted) return;
          if (result.isErr) {
            AppToast.error(context, (result as Err).failure.message);
          }
        },
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onChanged,
    required this.openCount,
    required this.partialCount,
  });

  final _TableFilter selected;
  final void Function(_TableFilter) onChanged;
  final int openCount;
  final int partialCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space8,
        AppDimensions.pagePaddingH,
        AppDimensions.space8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'TODAS',
              selected: selected == _TableFilter.all,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              onTap: () => onChanged(_TableFilter.all),
            ),
            const SizedBox(width: AppDimensions.space8),
            _FilterChip(
              label: 'ABIERTAS ($openCount)',
              selected: selected == _TableFilter.open,
              color: AppColors.statusGreen,
              onTap: () => onChanged(_TableFilter.open),
            ),
            const SizedBox(width: AppDimensions.space8),
            _FilterChip(
              label: 'PAGO PARCIAL ($partialCount)',
              selected: selected == _TableFilter.partiallyPaid,
              color: AppColors.statusOrange,
              onTap: () => onChanged(_TableFilter.partiallyPaid),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.35),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.statusBadge.copyWith(
            color: selected ? color : color.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        'No hay mesas con este filtro.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.darkDisabled : AppColors.lightDisabled,
        ),
      ),
    );
  }
}

// ── Sessions grid (with staggered entrance) ───────────────────────────────────

class _SessionsGrid extends StatefulWidget {
  const _SessionsGrid({
    required this.sessions,
    required this.onTap,
    this.onLongPress,
  });

  final List<TableSessionEntity> sessions;
  final void Function(TableSessionEntity) onTap;
  final void Function(TableSessionEntity)? onLongPress;

  @override
  State<_SessionsGrid> createState() => _SessionsGridState();
}

class _SessionsGridState extends State<_SessionsGrid>
    with SingleTickerProviderStateMixin {
  static bool _hasPlayed = false;

  late AnimationController _staggerCtrl;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    final n = widget.sessions.length.clamp(1, 20);
    _staggerCtrl = createStaggerController(vsync: this, itemCount: n);
    _anims = buildStaggerAnimations(controller: _staggerCtrl, itemCount: n);

    if (_hasPlayed) {
      _staggerCtrl.value = 1.0;
    } else {
      _staggerCtrl.forward();
      _hasPlayed = true;
    }
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.pagePaddingH,
        AppDimensions.pagePaddingH,
        AppDimensions.space64 + AppDimensions.pagePaddingH,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimensions.space12,
        mainAxisSpacing: AppDimensions.space12,
        // Altura exacta del contenido del talón — sin espacio muerto.
        mainAxisExtent: 118,
      ),
      itemCount: widget.sessions.length,
      itemBuilder: (_, i) {
        final anim = i < _anims.length ? _anims[i] : _anims.last;
        return StaggerItem(
          animation: anim,
          child: _TableCard(
            key: ValueKey(widget.sessions[i].id),
            session: widget.sessions[i],
            onTap: () => widget.onTap(widget.sessions[i]),
            onLongPress: widget.onLongPress != null
                ? () => widget.onLongPress!(widget.sessions[i])
                : null,
          ),
        );
      },
    );
  }
}

// ── Table card — talón de tiquete ─────────────────────────────────────────────

class _TableCard extends ConsumerWidget {
  const _TableCard({
    super.key,
    required this.session,
    required this.onTap,
    this.onLongPress,
  });

  final TableSessionEntity session;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = session.statusColor;
    final elapsed = _elapsedLabel(session.openedAt);

    // Saldo pendiente de la cuenta (ítems no cancelados y AÚN NO pagados) —
    // en vivo. Filtrar solo por !isCancelled hacía que una mesa reactivada
    // (ya saldada, con una ronda nueva) mostrara el total histórico completo
    // en vez del saldo real que se debe.
    final items = ref.watch(tableOrderProvider(session.id)).valueOrNull ?? [];
    final unpaid = items.where((i) => !i.isCancelled && !i.isPaid);
    final total = unpaid.fold(0, (s, i) => s + i.lineTotal);
    final itemCount = unpaid.fold(0, (s, i) => s + i.quantity);

    return ReceiptStub(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Encabezado: MESA N + tiempo ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'MESA ${session.tableNumber}',
                  style: AppTextStyles.receiptTitle.copyWith(
                    fontSize: 15,
                    color: AppColors.paperInk,
                  ),
                ),
              ),
              Text(
                elapsed,
                style: AppTextStyles.receiptSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _elapsedColor(session.openedAt),
                ),
              ),
            ],
          ),
          Text(
            session.apodo != null ? '"${session.apodo}"' : ' ',
            style: AppTextStyles.receiptSmall.copyWith(
              color: AppColors.paperInkSoft,
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const DashedDivider(padding: EdgeInsets.symmetric(vertical: 5)),

          // ── Total + ítems ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                itemCount == 0
                    ? 'sin pedidos'
                    : '$itemCount ítem${itemCount == 1 ? '' : 's'}',
                style: AppTextStyles.receiptSmall
                    .copyWith(color: AppColors.paperInkSoft),
              ),
              Text(
                total.toCop,
                style: AppTextStyles.receiptBodyBold
                    .copyWith(color: AppColors.paperInk),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Estado ───────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.circle, size: 7, color: statusColor),
              const SizedBox(width: 5),
              Text(
                session.statusLabel.toUpperCase(),
                style: AppTextStyles.receiptSmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _elapsedLabel(DateTime openedAt) {
    final d = DateTime.now().difference(openedAt);
    if (d.inHours >= 1) {
      return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
    }
    return '${d.inMinutes}m';
  }

  Color _elapsedColor(DateTime openedAt) {
    final d = DateTime.now().difference(openedAt);
    if (d.inHours >= 2) return AppColors.statusRed;
    if (d.inHours >= 1) return AppColors.statusOrange;
    return AppColors.paperInkSoft;
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNewTable});

  final VoidCallback onNewTable;

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
              Icons.table_restaurant_rounded,
              size: 80,
              color: AppColors.brand.withOpacity(0.3),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              'Sin mesas activas',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Abre una nueva mesa cuando lleguen clientes.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space32),
            FilledButton.icon(
              onPressed: onNewTable,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ABRIR PRIMERA MESA'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Text(
          'Error cargando mesas: $error',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.statusRed),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── New table dialog ──────────────────────────────────────────────────────────

class _NewTableDialog extends StatefulWidget {
  const _NewTableDialog({
    required this.tableNumber,
    required this.onOpen,
  });

  /// Auto-assigned number — read-only, passed by the parent.
  final int tableNumber;

  /// Called with the optional apodo; the table number is fixed.
  final Future<void> Function(String? apodo) onOpen;

  @override
  State<_NewTableDialog> createState() => _NewTableDialogState();
}

class _NewTableDialogState extends State<_NewTableDialog> {
  final _apodoController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _apodoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final apodo = _apodoController.text.trim();
    await widget.onOpen(apodo.isEmpty ? null : apodo);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.table_restaurant_rounded,
            color: AppColors.brand,
            size: AppDimensions.iconLg,
          ),
          const SizedBox(width: AppDimensions.space12),
          Text('Nueva Mesa', style: AppTextStyles.headlineSmall),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Auto-assigned table number (read-only) ───────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.space16,
            ),
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.brand.withOpacity(0.35)),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.tableNumber}',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.brand,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Mesa asignada automáticamente',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.brand.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space16),

          // ── Apodo (optional) ─────────────────────────────────────
          TextField(
            controller: _apodoController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.bodyLarge,
            decoration: const InputDecoration(
              labelText: 'Apodo (opcional)',
              hintText: 'Ej: Los cumpleañeros',
              prefixIcon: Icon(Icons.label_outline_rounded),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_isSubmitting ? 'Abriendo...' : 'ABRIR MESA'),
        ),
      ],
    );
  }
}
