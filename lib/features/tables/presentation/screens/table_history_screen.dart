import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../domain/entities/table_session_entity.dart';

/// Read-only list of closed [TableSession]s, newest first.
/// Tapping a row opens [TableHistoryDetailScreen] for full item detail.
class TableHistoryScreen extends ConsumerWidget {
  const TableHistoryScreen({super.key});

  static final _dateFormat = DateFormat('dd MMM yyyy · HH:mm', 'es_CO');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(closedSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Mesas', style: AppTextStyles.headlineSmall),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error al cargar el historial.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.statusRed,
            ),
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) return const _EmptyHistoryState();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.space12,
              horizontal: AppDimensions.pagePaddingH,
            ),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _HistoryStub(
              session: sessions[i],
              dateFormat: _dateFormat,
              onTap: () =>
                  context.push('/tables/historial/${sessions[i].id}'),
            ),
          );
        },
      ),
    );
  }
}

// ── History stub ───────────────────────────────────────────────────────────────

class _HistoryStub extends StatelessWidget {
  const _HistoryStub({
    required this.session,
    required this.dateFormat,
    required this.onTap,
  });

  final TableSessionEntity session;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final closedLabel = session.closedAt != null
        ? dateFormat.format(session.closedAt!)
        : dateFormat.format(session.openedAt);

    return ReceiptStub(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MESA ${session.tableNumber}',
                  style: AppTextStyles.receiptBodyBold
                      .copyWith(color: AppColors.paperInk),
                ),
                if (session.apodo != null)
                  Text(
                    '"${session.apodo}"',
                    style: AppTextStyles.receiptSmall.copyWith(
                      color: AppColors.paperInkSoft,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 11, color: AppColors.paperInkSoft),
                    const SizedBox(width: 4),
                    Text(closedLabel,
                        style: AppTextStyles.receiptSmall
                            .copyWith(color: AppColors.paperInkSoft)),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.paperInkSoft),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

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
              Icons.history_rounded,
              size: 72,
              color: AppColors.brand.withValues(alpha: 0.25),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              'Sin historial',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Las mesas cerradas aparecerán aquí.',
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
