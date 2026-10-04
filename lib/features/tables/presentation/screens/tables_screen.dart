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
import '../../../../core/widgets/stagger_entrance.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../payments/presentation/providers/payment_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/table_session_entity.dart';
import '../widgets/new_table_dialog.dart';
import '../../../../core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kTablesLayoutKey = 'thebase_tables_list_mode';

final tablesListModeProvider = StateNotifierProvider<TablesListModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TablesListModeNotifier(prefs);
});

class TablesListModeNotifier extends StateNotifier<bool> {
  TablesListModeNotifier(this._prefs) : super(_prefs.getBool(_kTablesLayoutKey) ?? false);
  final SharedPreferences _prefs;

  void toggle() {
    state = !state;
    _prefs.setBool(_kTablesLayoutKey, state);
  }
}


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
    final walletAsync = ref.watch(enrichedWalletSummaryProvider);
    final hasShift = walletAsync.valueOrNull?.hasInitialBase ?? false;
    final sessionsAsync = ref.watch(activeSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesas', style: AppTextStyles.headlineSmall),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isList = ref.watch(tablesListModeProvider);
              return IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(tablesListModeProvider.notifier).toggle();
                },
                tooltip: isList ? 'Cambiar a cuadrícula' : 'Cambiar a lista',
                icon: Icon(isList ? Icons.grid_view_rounded : Icons.view_list_rounded),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              );
            },
          ),
          IconButton(
            onPressed: () => context.push('/tables/historial'),
            tooltip: 'Historial de mesas',
            icon: const Icon(Icons.history_rounded),
            color: AppColors.brand,
          ),
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
      floatingActionButton: hasShift ? FloatingActionButton.extended(
        onPressed: () => _showNewTableDialog(context),
        icon: const Icon(Icons.table_restaurant_rounded),
        label: const Text('Nueva Mesa'),
      ) : null,
      body: !hasShift
          ? _NoShiftEmptyState()
          : sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorBody(error: e),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return _EmptyState(onNewTable: () => _showNewTableDialog(context));
                }
                final filtered = _applyFilter(sessions);
                final totalPending = ref.watch(totalPendingInTablesProvider);
                
                return Column(
                  children: [
                    // Total en Mesas Banner
                    Container(
                      margin: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, AppDimensions.space16, AppDimensions.pagePaddingH, 0),
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
                      decoration: BoxDecoration(
                        color: AppColors.statusOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                        border: Border.all(color: AppColors.statusOrange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL EN MESAS',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.statusOrange,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            totalPending.toCop,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.statusOrange,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space8),
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
      builder: (_) => NewTableDialog(
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

class _SessionsGrid extends ConsumerStatefulWidget {
  const _SessionsGrid({
    required this.sessions,
    required this.onTap,
    this.onLongPress,
  });

  final List<TableSessionEntity> sessions;
  final void Function(TableSessionEntity) onTap;
  final void Function(TableSessionEntity)? onLongPress;

  @override
  ConsumerState<_SessionsGrid> createState() => _SessionsGridState();
}

class _SessionsGridState extends ConsumerState<_SessionsGrid>
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
    final isList = ref.watch(tablesListModeProvider);
    
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.pagePaddingH,
        AppDimensions.pagePaddingH,
        AppDimensions.space64 + AppDimensions.pagePaddingH,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isList ? 1 : 2,
        crossAxisSpacing: AppDimensions.space12,
        mainAxisSpacing: AppDimensions.space12,
        mainAxisExtent: isList ? 84 : 124,
      ),
      itemCount: widget.sessions.length,
      itemBuilder: (_, i) {
        final anim = i < _anims.length ? _anims[i] : _anims.last;
        return StaggerItem(
          animation: anim,
          child: _TableCard(
            key: ValueKey(widget.sessions[i].id),
            session: widget.sessions[i],
            isListMode: isList,
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

// ── Table card — Dark Graphite Card ──────────────────────────────────────────

class _TableCard extends ConsumerWidget {
  const _TableCard({
    super.key,
    required this.session,
    required this.isListMode,
    required this.onTap,
    this.onLongPress,
  });

  final TableSessionEntity session;
  final bool isListMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = session.statusColor;
    final elapsed = _elapsedLabel(session.openedAt);

    final items = ref.watch(tableOrderProvider(session.id)).valueOrNull ?? [];
    final unpaid = items.where((i) => !i.isCancelled && !i.isPaid);
    final finSummary = ref.watch(tableFinancialSummaryProvider(session.id));
    final total = finSummary.pendingBalance > 0
        ? finSummary.pendingBalance
        : unpaid.fold(0, (s, i) => s + i.lineTotal);
    final itemCount = unpaid.fold(0, (s, i) => s + i.quantity);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Encabezado: MESA N + tiempo ──────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'MESA ${session.tableNumber}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.lightOnSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _elapsedColor(context, session.openedAt).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Text(
                        elapsed,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _elapsedColor(context, session.openedAt),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  session.apodo != null ? '"${session.apodo}"' : ' ',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Divider(
                  height: 12,
                  thickness: 1,
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                ),

                // ── Total + ítems ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      itemCount == 0
                          ? 'sin pedidos'
                          : '$itemCount ítem${itemCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                    Text(
                      total.toCop,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: total > 0 ? AppColors.primary : AppColors.statusGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // ── Estado ───────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      session.statusLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  Color _elapsedColor(BuildContext context, DateTime openedAt) {
    final d = DateTime.now().difference(openedAt);
    if (d.inHours >= 2) return AppColors.statusRed;
    if (d.inHours >= 1) return AppColors.statusOrange;
    return Theme.of(context).colorScheme.onSurfaceVariant;
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

class _NoShiftEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 80, color: AppColors.statusOrange.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Turno no iniciado', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.statusOrange)),
            const SizedBox(height: 8),
            Text('Debes iniciar el turno con tu base para operar.', style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Iniciar Turno con Base Inicial'),
            ),
          ],
        ),
      ),
    );
  }
}


