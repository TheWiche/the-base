import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_catalog_service.dart';
import '../../domain/entities/catalog_product.dart';

// ── Service singleton ─────────────────────────────────────────────────────────

final _catalogServiceProvider = Provider<LocalCatalogService>(
  (ref) => LocalCatalogService(),
);

// ── Catalog notifier ──────────────────────────────────────────────────────────

/// Manages the list of saved catalog products.
///
/// [save] upserts a product and refreshes.
/// [remove] deletes by id and refreshes.
/// The list is loaded once on build and re-fetched after every mutation.
class CatalogNotifier extends AsyncNotifier<List<CatalogProduct>> {
  LocalCatalogService get _service => ref.read(_catalogServiceProvider);

  @override
  Future<List<CatalogProduct>> build() => _service.getAll();

  Future<void> save(CatalogProduct product) async {
    await _service.upsert(product);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String id) async {
    await _service.delete(id);
    ref.invalidateSelf();
    await future;
  }
}

final catalogProvider =
    AsyncNotifierProvider<CatalogNotifier, List<CatalogProduct>>(
  CatalogNotifier.new,
);
