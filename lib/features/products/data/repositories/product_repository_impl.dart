import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/isar_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../models/product.dart';

/// Canonical display order for categories in the UI.
const _kCategoryOrder = [
  'Granizados',
  "Fría's",
  'Micheladas',
  'Gaseosas Solas',
  'Cocteles Paletas',
  'Mojitos',
  'Sangría',
  'Otros',
  'Vinos',
  'Licores',
  'Descorche',
];

const _kSeedVersion = 3;
const _kSeedVersionKey = 'thebase_seed_v';

final class ProductRepositoryImpl implements IProductRepository {
  // ── Seed data ─────────────────────────────────────────────────────────────
  // 44 canonical products extracted from the menu cartas.
  // isLiquor = true → triggers the special debt rule (cost added to waiter debt,
  //   not subtracted from active balance).
  static const _kSeed = <Map<String, Object>>[
    // ── GRANIZADOS — $12,000 — Standard ──────────────────────────────────
    {'name': 'Granizado Curacao',           'price': 12000, 'category': 'Granizados',       'isLiquor': false},
    {'name': 'Granizado Sandía Vodka',      'price': 12000, 'category': 'Granizados',       'isLiquor': false},
    {'name': 'Granizado Chingona Tequila',  'price': 12000, 'category': 'Granizados',       'isLiquor': false},
    {'name': 'Granizado Martini Manzana',   'price': 12000, 'category': 'Granizados',       'isLiquor': false},
    {'name': 'Granizado Smirnoff Ice',      'price': 12000, 'category': 'Granizados',       'isLiquor': false},
    {'name': 'Granizado Smirnoff Manzana',  'price': 12000, 'category': 'Granizados',       'isLiquor': false},
    {'name': 'Granizado Smirnoff Lulo',     'price': 12000, 'category': 'Granizados',       'isLiquor': false},
    {'name': 'Granizado Bellini',           'price': 12000, 'category': 'Granizados',       'isLiquor': false},
    {'name': 'Granizado Margarita',         'price': 12000, 'category': 'Granizados',       'isLiquor': false},

    // ── FRÍA'S / CERVEZAS — $6,000 — Standard ────────────────────────────
    {'name': 'Cerveza Club Colombia',       'price': 6000,  'category': "Fría's",           'isLiquor': false},
    {'name': 'Cerveza Águila Original',     'price': 6000,  'category': "Fría's",           'isLiquor': false},
    {'name': 'Cerveza Poker',               'price': 6000,  'category': "Fría's",           'isLiquor': false},
    {'name': 'Cerveza Águila Light',        'price': 6000,  'category': "Fría's",           'isLiquor': false},
    {'name': 'Cerveza Coronita',            'price': 6000,  'category': "Fría's",           'isLiquor': false},

    // ── MICHELADAS & SODAS — $8,000 — Standard ───────────────────────────
    {'name': "Michelada Fría's",            'price': 8000,  'category': 'Micheladas',       'isLiquor': false},
    {'name': 'Hatsu Frambuesa',             'price': 8000,  'category': 'Micheladas',       'isLiquor': false},
    {'name': 'Hatsu Sandía',               'price': 8000,  'category': 'Micheladas',       'isLiquor': false},
    {'name': 'Soda Bretaña',               'price': 8000,  'category': 'Micheladas',       'isLiquor': false},
    {'name': 'Soda Ginger',                'price': 8000,  'category': 'Micheladas',       'isLiquor': false},

    // ── COCTELES EN PALETAS — $8,000 — Standard ──────────────────────────
    {'name': 'Paleta Daiquiri Fresa',       'price': 8000,  'category': 'Cocteles Paletas', 'isLiquor': false},
    {'name': 'Paleta Margarita',            'price': 8000,  'category': 'Cocteles Paletas', 'isLiquor': false},
    {'name': 'Paleta Piña Colada',          'price': 8000,  'category': 'Cocteles Paletas', 'isLiquor': false},

    // ── MOJITOS — $15,000 — Standard ──────────────────────────────────────
    {'name': 'Mojito Fresa',               'price': 15000, 'category': 'Mojitos',           'isLiquor': false},
    {'name': 'Mojito Lulo',                'price': 15000, 'category': 'Mojitos',           'isLiquor': false},
    {'name': 'Mojito Maracuyá',            'price': 15000, 'category': 'Mojitos',           'isLiquor': false},
    {'name': 'Mojito Mango',               'price': 15000, 'category': 'Mojitos',           'isLiquor': false},
    {'name': 'Mojito Corozo',              'price': 15000, 'category': 'Mojitos',           'isLiquor': false},
    {'name': 'Mojito Tamarindo',           'price': 15000, 'category': 'Mojitos',           'isLiquor': false},
    {'name': 'Mojito Durazno',             'price': 15000, 'category': 'Mojitos',           'isLiquor': false},
    {'name': 'Mojito Piña',               'price': 15000, 'category': 'Mojitos',           'isLiquor': false},
    {'name': 'Mojito Limón',              'price': 15000, 'category': 'Mojitos',           'isLiquor': false},

    // ── SANGRÍA — $15,000 — Standard ──────────────────────────────────────
    {'name': 'Sangría Vino Tinto',         'price': 15000, 'category': 'Sangría',           'isLiquor': false},
    {'name': 'Sangría Vino Blanco',        'price': 15000, 'category': 'Sangría',           'isLiquor': false},
    {'name': 'Sangría Vino Rosado',        'price': 15000, 'category': 'Sangría',           'isLiquor': false},

    // ── VINOS POR BOTELLA — Special debt logic ─────────────────────────────
    {'name': 'Vino Estoril Dulce',                 'price': 70000,  'category': 'Vinos',   'isLiquor': true},
    {'name': 'Vino Isabella Blanco',               'price': 70000,  'category': 'Vinos',   'isLiquor': true},
    {'name': 'Vino Isabella Blanco Espumoso',      'price': 75000,  'category': 'Vinos',   'isLiquor': true},
    {'name': 'Vino Isabella Tinto Espumoso',       'price': 75000,  'category': 'Vinos',   'isLiquor': true},

    // ── LICORES BOTELLAS — Special debt logic ──────────────────────────────
    {'name': 'Botella Aguardiente',                'price': 105000, 'category': 'Licores', 'isLiquor': true},
    {"name": "Botella Buchanan's Deluxe/Master",   'price': 260000, 'category': 'Licores', 'isLiquor': true},
    {'name': 'Botella Tequila José Cuervo',        'price': 150000, 'category': 'Licores', 'isLiquor': true},
    {'name': 'Botella Old Parr',                   'price': 250000, 'category': 'Licores', 'isLiquor': true},
    {'name': 'Botella Ron Viejo de Caldas',        'price': 105000, 'category': 'Licores', 'isLiquor': true},

    // ── DESCORCHE — Special debt logic ─────────────────────────────────────
    {'name': 'Servicio de Descorche Completo',     'price': 60000,  'category': 'Descorche', 'isLiquor': true},

    // ── GASEOSAS SOLAS — $5,000 — Standard ───────────────────────────────
    // Bretaña, Ginger y Hatsu servidos solos en vaso, sin mezcla de cerveza.
    {'name': 'Bretaña Sola',           'price': 5000, 'category': 'Gaseosas Solas', 'isLiquor': false},
    {'name': 'Ginger Sola',            'price': 5000, 'category': 'Gaseosas Solas', 'isLiquor': false},
    {'name': 'Hatsu Frambuesa Sola',   'price': 5000, 'category': 'Gaseosas Solas', 'isLiquor': false},
    {'name': 'Hatsu Sandía Sola',      'price': 5000, 'category': 'Gaseosas Solas', 'isLiquor': false},

    // ── OTROS — Bebidas y acompañamientos ────────────────────────────────
    {'name': 'Cocacola',               'price': 5000,  'category': 'Otros', 'isLiquor': false},
    {'name': 'Gatorade',               'price': 7000,  'category': 'Otros', 'isLiquor': false},
    {'name': 'Agua',                   'price': 3000,  'category': 'Otros', 'isLiquor': false},
    {'name': 'Limón Trozos/Tajín',     'price': 3000,  'category': 'Otros', 'isLiquor': false},
    {'name': 'Detodito',               'price': 10000, 'category': 'Otros', 'isLiquor': false},
  ];

  // ── V2 incremental seed (for existing installations) ─────────────────────
  static const _kSeedV2 = <Map<String, Object>>[
    {'name': 'Bretaña Sola',           'price': 5000, 'category': 'Gaseosas Solas', 'isLiquor': false},
    {'name': 'Ginger Sola',            'price': 5000, 'category': 'Gaseosas Solas', 'isLiquor': false},
    {'name': 'Hatsu Frambuesa Sola',   'price': 5000, 'category': 'Gaseosas Solas', 'isLiquor': false},
    {'name': 'Hatsu Sandía Sola',      'price': 5000, 'category': 'Gaseosas Solas', 'isLiquor': false},
    {'name': 'Cocacola',               'price': 5000, 'category': 'Especiales',    'isLiquor': false},
    {'name': 'Gatorade',               'price': 7000, 'category': 'Especiales',    'isLiquor': false},
    {'name': 'Agua',                   'price': 3000, 'category': 'Especiales',    'isLiquor': false},
    {'name': 'Limón Trozos/Tajín',     'price': 3000, 'category': 'Especiales',    'isLiquor': false},
  ];

  // ── V3 incremental seed ───────────────────────────────────────────────────
  // Adds Detodito. seedMigrateV3() also renames 'Especiales' → 'Otros' in DB.
  static const _kSeedV3 = <Map<String, Object>>[
    {'name': 'Detodito', 'price': 10000, 'category': 'Otros', 'isLiquor': false},
  ];

  // ── IProductRepository ────────────────────────────────────────────────────

  @override
  Future<void> seedIfEmpty() async {
    final count = await IsarService.db.products.count();
    if (count > 0) return;

    await IsarService.write((isar) async {
      final products = _kSeed.map((data) {
        return Product()
          ..name = data['name'] as String
          ..price = data['price'] as int
          ..category = data['category'] as String
          ..isLiquor = data['isLiquor'] as bool
          ..isAvailable = true;
      }).toList();

      await isar.products.putAll(products);
    });

    // Fresh installs skip the incremental migration — they already have V2 data.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSeedVersionKey, _kSeedVersion);

    debugPrint('[ProductRepository] Seeded ${_kSeed.length} products (v$_kSeedVersion).');
  }

  /// V2 migration — inserts Gaseosas Solas + Especiales products for v1 installs.
  Future<void> seedMigrateV2() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_kSeedVersionKey) ?? 1;
    if (storedVersion >= 2) return;

    final existing = await IsarService.db.products.where().anyId().findAll();
    final existingNames = existing.map((p) => p.name).toSet();

    final toInsert = _kSeedV2
        .where((data) => !existingNames.contains(data['name'] as String))
        .map((data) => Product()
          ..name = data['name'] as String
          ..price = data['price'] as int
          ..category = data['category'] as String
          ..isLiquor = data['isLiquor'] as bool
          ..isAvailable = true)
        .toList();

    if (toInsert.isNotEmpty) {
      await IsarService.write((isar) async {
        await isar.products.putAll(toInsert);
      });
      debugPrint('[ProductRepository] Migration v2: inserted ${toInsert.length} new products.');
    }

    await prefs.setInt(_kSeedVersionKey, 2);
  }

  /// V3 migration — renames category 'Especiales' → 'Otros' and adds Detodito.
  Future<void> seedMigrateV3() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_kSeedVersionKey) ?? 1;
    if (storedVersion >= 3) return;

    final all = await IsarService.db.products.where().anyId().findAll();

    // Rename existing Especiales products to Otros.
    final toRename = all.where((p) => p.category == 'Especiales').toList();
    if (toRename.isNotEmpty) {
      for (final p in toRename) {
        p.category = 'Otros';
      }
      await IsarService.write((isar) async {
        await isar.products.putAll(toRename);
      });
      debugPrint('[ProductRepository] Migration v3: renamed ${toRename.length} Especiales → Otros.');
    }

    // Insert new V3 products (by name-deduplication).
    final existingNames = all.map((p) => p.name).toSet();
    final toInsert = _kSeedV3
        .where((data) => !existingNames.contains(data['name'] as String))
        .map((data) => Product()
          ..name = data['name'] as String
          ..price = data['price'] as int
          ..category = data['category'] as String
          ..isLiquor = data['isLiquor'] as bool
          ..isAvailable = true)
        .toList();

    if (toInsert.isNotEmpty) {
      await IsarService.write((isar) async {
        await isar.products.putAll(toInsert);
      });
      debugPrint('[ProductRepository] Migration v3: inserted ${toInsert.length} new products.');
    }

    await prefs.setInt(_kSeedVersionKey, 3);
  }

  @override
  Stream<List<ProductEntity>> watchAll() {
    return IsarService.db.products
        .where()
        .watch(fireImmediately: true)
        .map((list) {
          final sorted = [...list]
            ..sort((a, b) {
              final ai = _kCategoryOrder.indexOf(a.category);
              final bi = _kCategoryOrder.indexOf(b.category);
              final ci = (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
              return ci != 0 ? ci : a.name.compareTo(b.name);
            });
          return sorted.map(_toEntity).toList();
        });
  }

  @override
  Future<Result<void>> toggleAvailability(int productId) async {
    try {
      await IsarService.write((isar) async {
        final product = await isar.products.get(productId);
        if (product == null) return;
        product.isAvailable = !product.isAvailable;
        await isar.products.put(product);
      });
      return const Ok(null);
    } catch (e, st) {
      return Err(DatabaseFailure(
        message: 'No se pudo actualizar disponibilidad: $e',
        stackTrace: st,
      ));
    }
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  static ProductEntity _toEntity(Product p) => ProductEntity(
        id: p.id,
        name: p.name,
        price: p.price,
        category: p.category,
        isLiquor: p.isLiquor,
        isAvailable: p.isAvailable,
      );
}
