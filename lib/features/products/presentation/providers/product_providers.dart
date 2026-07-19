import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/category_order_provider.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../domain/usecases/toggle_availability_usecase.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final productRepositoryProvider = Provider<IProductRepository>(
  (ref) => ProductRepositoryImpl(),
);

// ── Reactive product list ─────────────────────────────────────────────────────

/// Raw product stream from Isar (sorted by name within category by the repo).
final _rawProductsProvider = StreamProvider<List<ProductEntity>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

/// Productos ordenados según el orden de categorías configurable.
/// Fires on every [isAvailable] toggle o cambio de orden.
final productsProvider = Provider<AsyncValue<List<ProductEntity>>>((ref) {
  final order = ref.watch(categoryOrderProvider.notifier);
  ref.watch(categoryOrderProvider); // rebuild al reordenar
  return ref.watch(_rawProductsProvider).whenData((list) {
    final sorted = [...list]
      ..sort((a, b) {
        final ci = order.indexOf(a.category).compareTo(order.indexOf(b.category));
        if (ci != 0) return ci;
        final si = (a.subcategory ?? '').compareTo(b.subcategory ?? '');
        return si != 0 ? si : a.name.compareTo(b.name);
      });
    return sorted;
  });
});

// ── Derived selectors ─────────────────────────────────────────────────────────

/// All unique category names in canonical order (for filter chips).
final productCategoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productsProvider).valueOrNull ?? [];
  // Preserve order from first occurrence (already sorted by repository).
  final seen = <String>{};
  return products.map((p) => p.category).where(seen.add).toList();
});

/// Products filtered by a specific category name.
final productsByCategoryProvider =
    Provider.family<List<ProductEntity>, String>((ref, category) {
  final products = ref.watch(productsProvider).valueOrNull ?? [];
  return products.where((p) => p.category == category).toList();
});

/// Distinct non-empty subcategories within a category (sorted). Empty when the
/// category has no subcategories assigned.
final subcategoriesProvider =
    Provider.family<List<String>, String>((ref, category) {
  final products = ref.watch(productsProvider).valueOrNull ?? [];
  final subs = <String>{};
  for (final p in products.where((p) => p.category == category)) {
    final s = p.subcategory;
    if (s != null && s.isNotEmpty) subs.add(s);
  }
  return subs.toList()..sort();
});

// ── Use case ──────────────────────────────────────────────────────────────────

final toggleAvailabilityUseCaseProvider = Provider<ToggleAvailabilityUseCase>(
  (ref) => ToggleAvailabilityUseCase(ref.read(productRepositoryProvider)),
);
