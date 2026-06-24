import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/domain/entities/pending_radar_item.dart';
import 'radar_item_tile.dart';

/// The "Por Mesa" view of El Radar.
///
/// Renders each [RadarTableGroup] as a card with a sticky table header,
/// followed by its pending items — oldest-first within the group.
///
/// Groups are sorted by their oldest item (most urgent table appears first),
/// ensuring the waiter's attention is drawn to the tables that have been
/// waiting longest.
class GroupedTableView extends StatelessWidget {
  const GroupedTableView({
    super.key,
    required this.groups,
    required this.onDelivered,
  });

  final List<RadarTableGroup> groups;
  final void Function(int itemId) onDelivered;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const _EmptyRadar();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space8,
        AppDimensions.pagePaddingH,
        AppDimensions.space64,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _TableGroupCard(
          group: group,
          onDelivered: onDelivered,
        );
      },
    );
  }
}

// ── Table group card ───────────────────────────────────────────────────────────

class _TableGroupCard extends StatelessWidget {
  const _TableGroupCard({required this.group, required this.onDelivered});

  final RadarTableGroup group;
  final void Function(int itemId) onDelivered;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Table header ─────────────────────────────────────────────
          _TableGroupHeader(group: group),

          // ── Item rows ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space12,
              0,
              AppDimensions.space12,
              AppDimensions.space8,
            ),
            child: Column(
              children: group.items.map((radarItem) {
                return RadarItemTile(
                  key: ValueKey(radarItem.item.id),
                  radarItem: radarItem,
                  showTableLabel: false, // header already identifies the table
                  onDelivered: () => onDelivered(radarItem.item.id),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Table group header ─────────────────────────────────────────────────────────

class _TableGroupHeader extends StatelessWidget {
  const _TableGroupHeader({required this.group});

  final RadarTableGroup group;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.brand.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Table icon
          Container(
            padding: const EdgeInsets.all(AppDimensions.space6),
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: const Icon(
              Icons.table_restaurant_rounded,
              color: AppColors.brand,
              size: AppDimensions.iconSm,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),

          // Table name + apodo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesa ${group.tableNumber}',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.brand,
                  ),
                ),
                if (group.tableApodo != null)
                  Text(
                    '"${group.tableApodo}"',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          // Pending count badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.badgePaddingH,
                vertical: AppDimensions.badgePaddingV),
            decoration: BoxDecoration(
              color: group.pendingCount > 2
                  ? AppColors.statusRed.withOpacity(0.15)
                  : AppColors.statusOrange.withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: group.pendingCount > 2
                    ? AppColors.statusRed.withOpacity(0.5)
                    : AppColors.statusOrange.withOpacity(0.5),
              ),
            ),
            child: Text(
              '${group.pendingCount} pendiente${group.pendingCount == 1 ? '' : 's'}',
              style: AppTextStyles.statusBadge.copyWith(
                color: group.pendingCount > 2
                    ? AppColors.statusRed
                    : AppColors.statusOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyRadar extends StatelessWidget {
  const _EmptyRadar();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: _RadarEmptyContent(),
    );
  }
}

class _RadarEmptyContent extends StatelessWidget {
  const _RadarEmptyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.radar_rounded,
          size: 80,
          color: AppColors.statusGreen.withOpacity(0.4),
        ),
        const SizedBox(height: AppDimensions.space16),
        Text(
          'Sin pedidos pendientes',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.statusGreen,
          ),
        ),
        const SizedBox(height: AppDimensions.space8),
        Text(
          'Todo entregado. El radar está limpio.',
          style: AppTextStyles.bodyLarge,
        ),
      ],
    );
  }
}
