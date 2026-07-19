/// Orden canónico de categorías del menú para toda la app (menú de agregar,
/// tiquete agrupado, listado de productos). Fuente única de verdad.
///
/// Antes vivía como `_kCategoryOrder` privado en el repositorio de productos;
/// se extrajo aquí para reusarlo desde la factura y el CRUD.
const List<String> kCategoryOrder = [
  'Granizados',
  "Fría's",
  'Micheladas',
  'Sodas',
  'Cocteles Paletas',
  'Mojitos',
  'Sangría',
  'Otros',
  'Vinos',
  'Licores',
  'Descorche',
];

/// Índice de orden de una categoría; las desconocidas van al final (999).
int categorySortIndex(String category) {
  final i = kCategoryOrder.indexOf(category);
  return i == -1 ? 999 : i;
}

/// Categoría por defecto para ítems sin categoría (personalizados / viejos).
const String kDefaultCategory = 'Otros';
