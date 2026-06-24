import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_providers.dart';

/// Agotados admin screen — lets the waiter mark menu items as out of stock.
///
/// Grouped by category. Each row has a Switch that flips [ProductEntity.isAvailable].
/// Unavailable items are grayed out with an "AGOTADO" badge.
/// Changes are persisted immediately to Isar and reflected across the app
/// (the [AddItemBottomSheet] blocks adding agotado items).
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Menú / Agotados', style: AppTextStyles.headlineSmall),
            Text(
              'Activa o desactiva ítems del menú',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          productsAsync.maybeWhen(
            data: (products) {
              final agotadoCount = products.where((p) => !p.isAvailable).length;
              if (agotadoCount == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: AppDimensions.space16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusRed.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      border: Border.all(
                          color: AppColors.statusRed.withOpacity(0.5)),
                    ),
                    child: Text(
                      '$agotadoCount AGOTADO${agotadoCount > 1 ? 'S' : ''}',
                      style: AppTextStyles.statusBadge
                          .copyWith(color: AppColors.statusRed),
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (products) {
          if (products.isEmpty) return const _EmptyState();
          return _ProductList(products: products);
        },
      ),
    );
  }
}

// ── Product list (grouped by category) ───────────────────────────────────────

class _ProductList extends ConsumerWidget {
  const _ProductList({required this.products});

  final List<ProductEntity> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by category (order already set by repository)
    final grouped = <String, List<ProductEntity>>{};
    for (final p in products) {
      (grouped[p.category] ??= []).add(p);
    }

    final categories = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimensions.space32),
      itemCount: categories.length,
      itemBuilder: (_, ci) {
        final category = categories[ci];
        final items = grouped[category]!;
        final isLiquorCategory = items.first.isLiquor;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category header ──────────────────────────────────
            _CategoryHeader(
              category: category,
              isLiquor: isLiquorCategory,
              availableCount: items.where((p) => p.isAvailable).length,
              total: items.length,
            ),

            // ── Product tiles ────────────────────────────────────
            ...items.map(
              (product) => _ProductTile(
                key: ValueKey(product.id),
                product: product,
                onToggle: () async {
                  final result = await ref
                      .read(toggleAvailabilityUseCaseProvider)
                      .call(product.id);
                  if (result.isErr && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${(result as Err).failure.message}',
                        ),
                        backgroundColor: AppColors.statusRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Category header ───────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.category,
    required this.isLiquor,
    required this.availableCount,
    required this.total,
  });

  final String category;
  final bool isLiquor;
  final int availableCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isLiquor ? AppColors.statusPurple : AppColors.brand;

    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.space16),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space8,
        AppDimensions.pagePaddingH,
        AppDimensions.space8,
      ),
      color: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSurfaceVariant,
      child: Row(
        children: [
          Icon(
            isLiquor
                ? Icons.wine_bar_rounded
                : Icons.local_bar_rounded,
            color: color,
            size: AppDimensions.iconSm,
          ),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(
              category.toUpperCase(),
              style: AppTextStyles.statusBadge.copyWith(color: color),
            ),
          ),
          Text(
            '$availableCount / $total disponibles',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product tile ──────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    super.key,
    required this.product,
    required this.onToggle,
  });

  final ProductEntity product;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAvailable = product.isAvailable;
    final nameColor = isAvailable
        ? (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)
        : (isDark ? AppColors.darkDisabled : AppColors.lightDisabled);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkOutlineVariant
                : AppColors.lightOutlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH,
          vertical: AppDimensions.space4,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: AppTextStyles.bodyMedium.copyWith(color: nameColor),
              ),
            ),
            if (!isAvailable) ...[
              const SizedBox(width: AppDimensions.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusRed.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                      color: AppColors.statusRed.withOpacity(0.5)),
                ),
                child: Text(
                  'AGOTADO',
                  style: AppTextStyles.statusBadge.copyWith(
                    color: AppColors.statusRed,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '\$ ${_fmt(product.price)}',
          style: AppTextStyles.mono.copyWith(
            fontSize: 12,
            color: isAvailable
                ? (product.isLiquor
                    ? AppColors.statusPurple
                    : AppColors.statusGreen)
                : (isDark ? AppColors.darkDisabled : AppColors.lightDisabled),
          ),
        ),
        trailing: Switch(
          value: isAvailable,
          onChanged: (_) => onToggle(),
          activeColor: AppColors.statusGreen,
          inactiveThumbColor:
              isDark ? AppColors.darkDisabled : AppColors.lightDisabled,
        ),
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 64,
            color: AppColors.brand.withOpacity(0.3),
          ),
          const SizedBox(height: AppDimensions.space16),
          Text(
            'Menú no cargado',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Reinicia la app para cargar el menú.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Text(
          'Error cargando menú: $error',
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.statusRed),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
