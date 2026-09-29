import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final closedLabel = session.closedAt != null
        ? dateFormat.format(session.closedAt!)
        : dateFormat.format(session.openedAt);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
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
                          if (session.apodo != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '"${session.apodo}"',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : AppColors.lightOnSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 13,
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.lightOnSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            closedLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.lightOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
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
