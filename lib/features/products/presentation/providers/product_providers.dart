import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../domain/usecases/toggle_availability_usecase.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final productRepositoryProvider = Provider<IProductRepository>(
  (ref) => ProductRepositoryImpl(),
);

// ── Reactive product list ─────────────────────────────────────────────────────

/// All 44 menu products, sorted by canonical category order then by name.
/// Fires on every [isAvailable] toggle.
final productsProvider = StreamProvider<List<ProductEntity>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

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

// ── Use case ──────────────────────────────────────────────────────────────────

final toggleAvailabilityUseCaseProvider = Provider<ToggleAvailabilityUseCase>(
  (ref) => ToggleAvailabilityUseCase(ref.read(productRepositoryProvider)),
);
