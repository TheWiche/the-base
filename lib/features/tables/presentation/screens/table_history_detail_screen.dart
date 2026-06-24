import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../domain/entities/table_session_entity.dart';

/// Read-only view of a closed [TableSessionEntity] — all items displayed,
/// no add/cancel/pay actions. Provides a REACTIVAR button (Épica 7.4).
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

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionByIdProvider(widget.sessionId));
    final itemsAsync = ref.watch(tableOrderProvider(widget.sessionId));

    sessionAsync.whenData((s) {
      if (s != null) _session = s;
    });

    return Scaffold(
      appBar: _buildAppBar(_session),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: itemsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error al cargar el pedido.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.statusRed),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyBody()
                  : _ReadOnlyBody(items: items),
            ),
          ),
          // ── Reactivar bar ──────────────────────────────────────────────
          if (_session != null)
            itemsAsync.maybeWhen(
              data: (items) => _ReactivarBar(
                session: _session!,
                items: items,
                onReactivate: () => _reactivate(_session!),
              ),
              orElse: () => const SizedBox.shrink(),
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
        if (session != null)
          Container(
            margin: const EdgeInsets.only(right: AppDimensions.space16),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space10,
              vertical: AppDimensions.space4,
            ),
            decoration: BoxDecoration(
              color: AppColors.darkDisabled.withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: AppColors.darkDisabled.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'CERRADA',
              style: AppTextStyles.statusBadge.copyWith(
                color: AppColors.darkDisabled,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _reactivate(TableSessionEntity session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.restore_rounded,
          color: AppColors.brand,
          size: AppDimensions.iconXl,
        ),
        title: Text('¿Reactivar mesa?', style: AppTextStyles.headlineSmall),
        content: Text(
          'Mesa ${session.tableNumber} volverá a aparecer como abierta. '
          'Los ítems y pagos existentes se conservan.',
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
            label: const Text('REACTIVAR'),
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
      _showError(failure);
    } else {
      // Session is now active — go to tables grid where it'll appear.
      context.go('/tables');
    }
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

// ── Read-only item list ────────────────────────────────────────────────────────

class _ReadOnlyBody extends StatelessWidget {
  const _ReadOnlyBody({required this.items});

  final List<OrderItemEntity> items;

  @override
  Widget build(BuildContext context) {
    final pending =
        items.where((i) => i.isActive).toList();
    final delivered =
        items.where((i) => i.isDelivered && !i.isPaid).toList();
    final paid = items.where((i) => i.isPaid).toList();
    final cancelled = items.where((i) => i.isCancelled).toList();

    return CustomScrollView(
      slivers: [
        if (pending.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              label: 'PENDIENTES',
              count: pending.length,
              color: AppColors.statusOrange,
            ),
          ),
          _ItemSliver(items: pending),
        ],
        if (delivered.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              label: 'ENTREGADOS',
              count: delivered.length,
              color: AppColors.statusBlue,
            ),
          ),
          _ItemSliver(items: delivered),
        ],
        if (paid.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              label: 'PAGADOS',
              count: paid.length,
              color: AppColors.statusGreen,
            ),
          ),
          _ItemSliver(items: paid),
        ],
        if (cancelled.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              label: 'CANCELADOS',
              count: cancelled.length,
              color: AppColors.statusRed,
            ),
          ),
          _ItemSliver(items: cancelled),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
    );
  }
}

class _ItemSliver extends StatelessWidget {
  const _ItemSliver({required this.items});

  final List<OrderItemEntity> items;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _ReadOnlyItemTile(item: items[i]),
          childCount: items.length,
        ),
      ),
    );
  }
}

// ── Read-only tile ─────────────────────────────────────────────────────────────

class _ReadOnlyItemTile extends StatelessWidget {
  const _ReadOnlyItemTile({required this.item});

  final OrderItemEntity item;

  static final _fmt = DateFormat('HH:mm', 'es_CO');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = item.isCancelled
        ? (isDark ? AppColors.darkDisabled : AppColors.lightDisabled)
        : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: item.isCancelled
              ? AppColors.statusRed.withValues(alpha: 0.25)
              : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.isCancelled
                  ? AppColors.statusRed.withValues(alpha: 0.08)
                  : item.categoryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(
              item.isCancelled ? Icons.cancel_rounded : item.categoryIcon,
              color: item.isCancelled ? AppColors.statusRed : item.categoryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),

          // Name + meta
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.quantity > 1
                      ? '${item.productName}  ×${item.quantity}'
                      : item.productName,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: textColor,
                    decoration: item.isCancelled
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: AppColors.statusRed,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.space2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 10,
                      color: isDark
                          ? AppColors.darkDisabled
                          : AppColors.lightDisabled,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _fmt.format(item.orderedAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkDisabled
                            : AppColors.lightDisabled,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Price
          Text(
            item.lineTotal.toCop,
            style: AppTextStyles.titleMedium.copyWith(
              color: item.isCancelled
                  ? AppColors.statusRed.withValues(alpha: 0.5)
                  : item.categoryColor,
              decoration: item.isCancelled
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space16,
        AppDimensions.pagePaddingH,
        AppDimensions.space8,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          Text(label, style: AppTextStyles.statusBadge.copyWith(color: color)),
          const SizedBox(width: AppDimensions.space8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.statusBadge.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reactivar bottom bar ───────────────────────────────────────────────────────

class _ReactivarBar extends StatelessWidget {
  const _ReactivarBar({
    required this.session,
    required this.items,
    required this.onReactivate,
  });

  final TableSessionEntity session;
  final List<OrderItemEntity> items;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    final totalOrdered = items
        .where((i) => !i.isCancelled)
        .fold(0, (sum, i) => sum + i.lineTotal);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space12,
        AppDimensions.pagePaddingH,
        AppDimensions.space12 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL PEDIDO',
                  style: AppTextStyles.statusBadge.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalOrdered.toCop,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.lightOnSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space16),
          FilledButton.icon(
            onPressed: onReactivate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: const Color(0xFF1A0A00),
              minimumSize: const Size(100, 52),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space20,
                vertical: AppDimensions.space12,
              ),
            ),
            icon: const Icon(Icons.restore_rounded),
            label: Text(
              'REACTIVAR',
              style: AppTextStyles.labelLarge
                  .copyWith(color: const Color(0xFF1A0A00)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty body ─────────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Sin ítems en esta mesa.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkDisabled
              : AppColors.lightDisabled,
        ),
      ),
    );
  }
}
