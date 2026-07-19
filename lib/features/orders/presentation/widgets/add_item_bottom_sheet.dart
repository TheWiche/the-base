import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/settings/bar_settings_provider.dart';
import '../../../../core/settings/category_icon_provider.dart';
import '../../../../core/settings/category_order_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../catalog/domain/entities/catalog_product.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../providers/order_providers.dart';
import '../../domain/entities/order_item_entity.dart';

/// Modal "Agregar a la Mesa" — diseño tipo dashboard:
/// header con mesa/bar, buscador, chips de categoría CON ícono (todas
/// visibles), lista de productos con botón "+", tarjeta "¿Algo fuera del
/// menú?" y barra inferior con total + "Ver pedido (N)".
class AddItemBottomSheet extends ConsumerStatefulWidget {
  const AddItemBottomSheet({
    super.key,
    required this.tableSessionId,
    required this.onAdd,
  });

  final int tableSessionId;
  final void Function(AddItemParams params) onAdd;

  static Future<void> show({
    required BuildContext context,
    required int tableSessionId,
    required void Function(AddItemParams params) onAdd,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemBottomSheet(
        tableSessionId: tableSessionId,
        onAdd: onAdd,
      ),
    );
  }

  @override
  ConsumerState<AddItemBottomSheet> createState() =>
      _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends ConsumerState<AddItemBottomSheet> {
  final _srchCtrl = TextEditingController();

  String? _selectedMenuCat; // se auto-selecciona la primera al cargar
  String? _selectedSubcat;
  String _searchQuery = '';
  bool _isSubmitting = false;
  final _cart = <_CartEntry>[];

  @override
  void dispose() {
    _srchCtrl.dispose();
    super.dispose();
  }

  // ── Cart ──────────────────────────────────────────────────────────────────

  int get _cartCount => _cart.fold(0, (s, e) => s + e.quantity);
  int get _cartTotal => _cart.fold(0, (s, e) => s + e.price * e.quantity);

  void _addToCart(String name, int price, ProductCategory category,
      {int qty = 1, String? note, String? menuCategory, String? subcategory}) {
    HapticFeedback.lightImpact();
    setState(() {
      final idx = _cart.indexWhere((e) => e.name == name);
      if (idx >= 0) {
        _cart[idx].quantity += qty;
      } else {
        _cart.add(_CartEntry(
            name: name,
            price: price,
            category: category,
            quantity: qty,
            note: note,
            menuCategory: menuCategory,
            subcategory: subcategory));
      }
    });
  }

  void _changeCartQty(String name, int delta) {
    setState(() {
      final idx = _cart.indexWhere((e) => e.name == name);
      if (idx < 0) return;
      final newQty = _cart[idx].quantity + delta;
      if (newQty <= 0) {
        _cart.removeAt(idx);
      } else {
        _cart[idx].quantity = newQty;
      }
    });
  }

  void _setCartNote(String name, String? note) {
    setState(() {
      final idx = _cart.indexWhere((e) => e.name == name);
      if (idx >= 0) {
        _cart[idx].note = (note == null || note.isEmpty) ? null : note;
      }
    });
  }

  void _submitCart() {
    if (_cart.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    for (final e in _cart) {
      widget.onAdd(AddItemParams(
        tableSessionId: widget.tableSessionId,
        productName: e.name,
        price: e.price,
        quantity: e.quantity,
        category: e.category,
        note: e.note,
        menuCategory: e.menuCategory,
        subcategory: e.subcategory,
      ));
    }
    Navigator.of(context).pop();
  }

  // ── Product pick ──────────────────────────────────────────────────────────

  void _pickProduct(ProductEntity p) {
    if (!p.isAvailable) return;
    if (p.isComposable && p.baseCategories.isNotEmpty) {
      _pickComposableBase(p);
      return;
    }
    _addToCart(p.name, p.price,
        p.isLiquor ? ProductCategory.liquor : ProductCategory.standard,
        menuCategory: p.category);
  }

  /// Selector de base para un producto combinable (ej. Michelada → cerveza/soda).
  void _pickComposableBase(ProductEntity p) {
    final all = ref.read(productsProvider).valueOrNull ?? [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${p.name} — elige la base',
                  style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              for (final baseCat in p.baseCategories) ...[
                Text(_baseGroupTitle(baseCat),
                    style: AppTextStyles.statusBadge
                        .copyWith(color: AppColors.primary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: all
                      .where((x) => x.category == baseCat && x.isAvailable)
                      .map((opt) => ActionChip(
                            label: Text(_baseLabel(opt.name)),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _addToCart(
                                '${p.name} · ${_baseLabel(opt.name)}',
                                p.price,
                                ProductCategory.standard,
                                menuCategory: p.category,
                                subcategory: baseCat,
                              );
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _baseLabel(String name) => name
      .replaceFirst(RegExp(r'^(Cerveza|Soda|Gaseosa)\s+'), '')
      .replaceFirst(RegExp(r'\s+Sola$'), '')
      .trim();

  String _baseGroupTitle(String category) {
    final c = category.toLowerCase();
    if (c.contains('fría') || c.contains('cerve')) return 'CERVEZA';
    if (c.contains('gaseosa') || c.contains('soda')) return 'SODA';
    return category.toUpperCase();
  }

  // ── Custom item ("¿Algo fuera del menú?") ─────────────────────────────────

  void _openCustomForm() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CustomItemSheet(
        onAdd: (name, price, qty, note, isLiquor) {
          _addToCart(
            name,
            price,
            isLiquor ? ProductCategory.liquor : ProductCategory.standard,
            qty: qty,
            note: note,
          );
        },
        onPickCatalog: (p) => _addToCart(p.name, p.price, p.category),
      ),
    );
  }

  // ── Ver pedido (carrito) ──────────────────────────────────────────────────

  void _openCart() {
    if (_cart.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void refresh() {
            setSheetState(() {});
            setState(() {});
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Tu pedido', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final e in [..._cart])
                          _CartLine(
                            entry: e,
                            onMinus: () {
                              _changeCartQty(e.name, -1);
                              refresh();
                            },
                            onPlus: () {
                              _changeCartQty(e.name, 1);
                              refresh();
                            },
                            onNote: () async {
                              final note = await _promptNote(e);
                              if (note != null) {
                                _setCartNote(e.name, note.isEmpty ? null : note);
                                refresh();
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTextStyles.titleMedium),
                      Text(_cartTotal.toCop,
                          style: AppTextStyles.headlineSmall
                              .copyWith(color: AppColors.secondaryDark)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _cart.isEmpty
                        ? null
                        : () {
                            Navigator.of(ctx).pop();
                            _submitCart();
                          },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: Text('Agregar a la mesa ($_cartCount)'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) => setState(() {}));
  }

  Future<String?> _promptNote(_CartEntry entry) {
    final ctrl = TextEditingController(text: entry.note ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(entry.name,
            style: AppTextStyles.labelMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: 'Ej: sin hielo, con limón...',
            prefixIcon: Icon(Icons.edit_note_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightBackground;

    final menuAll = ref.watch(productsProvider).valueOrNull ?? [];
    final available = menuAll.where((p) => p.isAvailable).toList();
    final icons = ref.watch(categoryIconsProvider);
    final order = ref.watch(categoryOrderProvider);
    final session = ref.watch(tableSessionByIdProvider(widget.tableSessionId));
    final barName = ref.watch(barNameProvider);

    // Todas las categorías con productos disponibles, en el orden configurado.
    final present = <String>{for (final p in available) p.category};
    final categories = <String>[
      ...order.where(present.contains),
      ...present.where((c) => !order.contains(c)),
    ];

    // Auto-seleccionar la primera categoría para mostrar productos de una.
    if (_selectedMenuCat == null && categories.isNotEmpty) {
      _selectedMenuCat = categories.first;
    }

    final searching = _searchQuery.trim().isNotEmpty;
    final shown = searching
        ? available
            .where((p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList()
        : available.where((p) {
            if (p.category != _selectedMenuCat) return false;
            if (_selectedSubcat != null && p.subcategory != _selectedSubcat) {
              return false;
            }
            return true;
          }).toList();

    final subcats = searching || _selectedMenuCat == null
        ? const <String>[]
        : (available
            .where((p) =>
                p.category == _selectedMenuCat && p.subcategory != null)
            .map((p) => p.subcategory!)
            .toSet()
            .toList()
          ..sort());

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.94,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
        child: Column(
          children: [
            // ── Drag handle ─────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_shopping_cart_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Agregar a la Mesa',
                            style: AppTextStyles.headlineSmall),
                        Text(
                          session == null
                              ? barName
                              : 'Mesa ${session.tableNumber}  ·  $barName',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // ── Buscador ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: TextField(
                controller: _srchCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _srchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),

            // ── Contenido scrolleable ───────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  // Chips de categorías (TODAS visibles, con ícono).
                  if (!searching)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cat in categories)
                          _CategoryChip(
                            label: cat,
                            icon: categoryIconFor(icons, cat),
                            selected: cat == _selectedMenuCat,
                            isDark: isDark,
                            onTap: () => setState(() {
                              _selectedMenuCat = cat;
                              _selectedSubcat = null;
                            }),
                          ),
                      ],
                    ),

                  // Subcategorías de la categoría activa.
                  if (subcats.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _SubChip(
                          label: 'Todas',
                          selected: _selectedSubcat == null,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedSubcat = null),
                        ),
                        for (final s in subcats)
                          _SubChip(
                            label: s,
                            selected: _selectedSubcat == s,
                            isDark: isDark,
                            onTap: () => setState(() =>
                                _selectedSubcat = _selectedSubcat == s ? null : s),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Título de sección + conteo.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          searching ? 'Resultados' : (_selectedMenuCat ?? ''),
                          style: AppTextStyles.headlineMedium,
                        ),
                      ),
                      Text(
                        '${shown.length} producto${shown.length == 1 ? '' : 's'}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Lista de productos.
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        searching
                            ? 'Nada coincide con "$_searchQuery".'
                            : 'Sin productos disponibles aquí.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurface,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLg),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutline
                              : AppColors.lightOutline,
                        ),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < shown.length; i++) ...[
                            _ProductRow(
                              product: shown[i],
                              inCartQty: _cart
                                  .where((e) =>
                                      e.name == shown[i].name ||
                                      e.name.startsWith('${shown[i].name} ·'))
                                  .fold(0, (s, e) => s + e.quantity),
                              isDark: isDark,
                              onAdd: () => _pickProduct(shown[i]),
                            ),
                            if (i < shown.length - 1)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: isDark
                                    ? AppColors.darkOutlineVariant
                                    : AppColors.lightOutlineVariant,
                              ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),

                  // ¿Algo fuera del menú?
                  _OutOfMenuCard(isDark: isDark, onTap: _openCustomForm),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Barra inferior: resumen + Ver pedido ────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                10 + MediaQuery.of(context).viewPadding.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_cartCount producto${_cartCount == 1 ? '' : 's'}',
                          style: AppTextStyles.bodySmall,
                        ),
                        Row(
                          children: [
                            Text('Total: ', style: AppTextStyles.titleSmall),
                            Text(
                              _cartTotal.toCop,
                              style: AppTextStyles.titleSmall
                                  .copyWith(color: AppColors.secondaryDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _cart.isEmpty ? null : _openCart,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(150, 52),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, size: 20),
                    label: Text('Ver pedido ($_cartCount)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cart entry ────────────────────────────────────────────────────────────────

class _CartEntry {
  _CartEntry({
    required this.name,
    required this.price,
    required this.category,
    this.quantity = 1,
    this.note,
    this.menuCategory,
    this.subcategory,
  });

  final String name;
  final int price;
  final ProductCategory category;
  int quantity;
  String? note;
  final String? menuCategory;
  final String? subcategory;
}

// ── Category chip (ícono + nombre) ────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? const Color(0xFF241A05)
        : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubChip extends StatelessWidget {
  const _SubChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected
                ? AppColors.primary
                : (isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Product row (nombre · precio · +) ─────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.inCartQty,
    required this.isDark,
    required this.onAdd,
  });

  final ProductEntity product;
  final int inCartQty;
  final bool isDark;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  color:
                      isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                ),
              ),
            ),
            Text(
              product.price.toCop,
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.secondaryDark),
            ),
            const SizedBox(width: 12),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    color: AppColors.primary.withOpacity(0.08),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.primary, size: 22),
                ),
                if (inCartQty > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$inCartQty',
                        style: AppTextStyles.statusBadge
                            .copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── "¿Algo fuera del menú?" ───────────────────────────────────────────────────

class _OutOfMenuCard extends StatelessWidget {
  const _OutOfMenuCard({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.6),
            width: 1.4,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          color: AppColors.primary.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.playlist_add_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Algo fuera del menú?',
                      style: AppTextStyles.titleMedium),
                  Text(
                    'Agrega productos personalizados o especiales.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Cart line (dentro de "Ver pedido") ────────────────────────────────────────

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.entry,
    required this.onMinus,
    required this.onPlus,
    required this.onNote,
  });

  final _CartEntry entry;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: AppTextStyles.bodyLarge),
                Text(
                  (entry.price * entry.quantity).toCop,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.secondaryDark),
                ),
                if (entry.note != null)
                  Text(
                    '↳ ${entry.note}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.statusOrange,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNote,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.sticky_note_2_outlined, size: 20),
            tooltip: 'Nota',
          ),
          IconButton(
            onPressed: onMinus,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
          ),
          Text('${entry.quantity}', style: AppTextStyles.titleMedium),
          IconButton(
            onPressed: onPlus,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline_rounded,
                size: 22, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Custom item sheet ─────────────────────────────────────────────────────────

class _CustomItemSheet extends ConsumerStatefulWidget {
  const _CustomItemSheet({required this.onAdd, required this.onPickCatalog});

  final void Function(
      String name, int price, int qty, String? note, bool isLiquor) onAdd;
  final void Function(CatalogProduct) onPickCatalog;

  @override
  ConsumerState<_CustomItemSheet> createState() => _CustomItemSheetState();
}

class _CustomItemSheetState extends ConsumerState<_CustomItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _note = TextEditingController();
  int _qty = 1;
  bool _isLiquor = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _parsedPrice => int.tryParse(_price.text.replaceAll('.', ''));

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    final price = _parsedPrice;
    if (price == null || price <= 0) return;
    final note = _note.text.trim();
    widget.onAdd(
      _name.text.trim(),
      price,
      _qty,
      note.isEmpty ? null : note,
      _isLiquor,
    );
    Navigator.of(context).pop();
  }

  Future<void> _saveToCatalog() async {
    final name = _name.text.trim();
    final price = _parsedPrice;
    if (name.isEmpty || price == null || price <= 0) return;
    await ref.read(catalogProvider.notifier).save(CatalogProduct(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          price: price,
          category:
              _isLiquor ? ProductCategory.liquor : ProductCategory.standard,
        ));
    if (mounted) {
      AppToast.success(context, '"$name" guardado en acceso rápido.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider).valueOrNull ?? [];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Fuera del menú', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 14),

              // Acceso rápido (personalizados guardados).
              if (catalog.isNotEmpty) ...[
                Text('ACCESO RÁPIDO',
                    style: AppTextStyles.statusBadge
                        .copyWith(color: AppColors.primary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in catalog)
                      ActionChip(
                        label: Text('${p.name} · ${p.price.toCop}',
                            style: AppTextStyles.labelSmall),
                        onPressed: () {
                          widget.onPickCatalog(p);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          labelText: 'Precio', prefixText: '\$ '),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').replaceAll('.', ''));
                        return (n == null || n <= 0) ? 'Inválido' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed:
                        _qty > 1 ? () => setState(() => _qty--) : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text('$_qty', style: AppTextStyles.headlineSmall),
                  IconButton(
                    onPressed: () => setState(() => _qty++),
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Ej: sin hielo...',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isLiquor,
                onChanged: (v) => setState(() => _isLiquor = v),
                activeColor: AppColors.statusPurple,
                title: Text('Es licor (botella)', style: AppTextStyles.bodyMedium),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saveToCatalog,
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: const Text('Guardar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _add,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
