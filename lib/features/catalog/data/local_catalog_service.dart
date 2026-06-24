import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/catalog_product.dart';

/// Persists the waiter's quick-access product catalog in SharedPreferences.
///
/// Each product is stored as a JSON string in a String list under [_key].
/// Operations are O(n) for the small catalog sizes expected (< 50 items).
final class LocalCatalogService {
  static const _key = 'thebase_catalog_v1';

  Future<List<CatalogProduct>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final result = <CatalogProduct>[];
    for (final s in raw) {
      try {
        result.add(
          CatalogProduct.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map)),
        );
      } catch (e) {
        debugPrint('[CatalogService] Skipping corrupt entry: $e');
      }
    }
    return result;
  }

  /// Adds or replaces a product (matched by [CatalogProduct.id]).
  Future<void> upsert(CatalogProduct product) async {
    final products = await getAll();
    final idx = products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      products[idx] = product;
    } else {
      products.add(product);
    }
    await _persist(products);
  }

  Future<void> delete(String id) async {
    final products = await getAll();
    products.removeWhere((p) => p.id == id);
    await _persist(products);
  }

  Future<void> _persist(List<CatalogProduct> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      products.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }
}
