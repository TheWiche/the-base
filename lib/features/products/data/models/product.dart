import 'package:isar/isar.dart';

part 'product.g.dart';

/// Isar model for a pre-loaded menu product.
///
/// All 44 products are seeded on first launch via [ProductRepositoryImpl.seedIfEmpty].
/// The [isAvailable] flag is the only mutable field — waiters toggle it via the
/// Agotados screen when an item runs out during the shift.
@collection
class Product {
  Id id = Isar.autoIncrement;

  late String name;
  late int price;

  /// Display category: "Granizados", "Fría's", "Mojitos", "Licores", etc.
  @Index(type: IndexType.value)
  late String category;

  /// Optional menu subcategory ("Cerveza", "Soda", …) — editable desde el CRUD.
  String? subcategory;

  /// Producto combinable (ej. Michelada): al agregar se elige una "base".
  bool isComposable = false;

  /// Categorías cuyos productos sirven de base (ej. ["Fría's", "Gaseosas Solas"]).
  /// Solo aplica cuando [isComposable] es true.
  List<String> baseCategories = [];

  /// True for Licores / Vinos / Descorche — triggers the special debt rule.
  /// Standard cocktails and beers are false.
  late bool isLiquor;

  /// Waiter-controlled availability flag.
  /// False = item is grayed out and blocked from being added to any order.
  @Index(type: IndexType.value)
  late bool isAvailable;
}
