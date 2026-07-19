import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/settings/bar_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../orders/presentation/widgets/receipt_view.dart';
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
                  : _ReceiptDetailBody(
                      session: _session,
                      items: items,
                      barName: ref.watch(barNameProvider),
                    ),
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

  void _showError(Failure failure) => AppToast.error(context, failure.message);
}

// ── Detalle = tiquete completo (read-only) ────────────────────────────────────

class _ReceiptDetailBody extends StatelessWidget {
  const _ReceiptDetailBody({
    required this.session,
    required this.items,
    required this.barName,
  });

  final TableSessionEntity? session;
  final List<OrderItemEntity> items;
  final String barName;

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
                apodo: session!.apodo,
                openedAt: session!.openedAt,
              ),
            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
            ReceiptGrouped(items: items),
            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
            ReceiptFooter(items: items, showThanks: true),
          ],
        ),
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
