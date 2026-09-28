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
  ProductEntity? _lastAddedProduct;

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
    final cleanNote = (note == null || note.trim().isEmpty) ? null : note.trim();
    setState(() {
      final idx = _cart.indexWhere((e) => e.name == name && e.note == cleanNote);
      if (idx >= 0) {
        _cart[idx].quantity += qty;
      } else {
        _cart.add(_CartEntry(
            name: name,
            price: price,
            category: category,
            quantity: qty,
            note: cleanNote,
            menuCategory: menuCategory,
            subcategory: subcategory));
      }
    });
  }

  void _changeCartQty(_CartEntry entry, int delta) {
    setState(() {
      final idx = _cart.indexOf(entry);
      if (idx < 0) return;
      final newQty = entry.quantity + delta;
      if (newQty <= 0) {
        _cart.removeAt(idx);
      } else {
        entry.quantity = newQty;
      }
    });
  }

  void _setCartNote(_CartEntry entry, String? note) {
    setState(() {
      final clean = (note == null || note.trim().isEmpty) ? null : note.trim();
      entry.note = clean;
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
    if (p.defaultNotes.isNotEmpty) {
      setState(() => _lastAddedProduct = p);
    }
  }

  void _openQuickNoteSheet(ProductEntity p) {
    if (!p.isAvailable) return;
    if (p.isComposable && p.baseCategories.isNotEmpty) {
      _pickComposableBase(p);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickNoteSheet(
        product: p,
        onAdd: (qty, note) {
          _addToCart(
            p.name,
            p.price,
            p.isLiquor ? ProductCategory.liquor : ProductCategory.standard,
            qty: qty,
            note: note,
            menuCategory: p.category,
          );
        },
      ),
    );
  }

  void _applyNoteToLastAdded(String note) {
    if (_lastAddedProduct == null) return;
    final name = _lastAddedProduct!.name;
    HapticFeedback.selectionClick();
    setState(() {
      final idx = _cart.lastIndexWhere((e) => e.name == name);
      if (idx >= 0) {
        final item = _cart[idx];
        if (item.quantity > 1) {
          item.quantity -= 1;
          _addToCart(
            item.name,
            item.price,
            item.category,
            qty: 1,
            note: note,
            menuCategory: item.menuCategory,
            subcategory: item.subcategory,
          );
        } else {
          item.note = (item.note == null || item.note!.isEmpty)
              ? note
              : '${item.note}, $note';
        }
      }
      _lastAddedProduct = null;
    });
    AppToast.success(context, 'Nota aplicada: "$note"');
  }

  Future<void> _openCustomNoteForLastAdded() async {
    if (_lastAddedProduct == null) return;
    final name = _lastAddedProduct!.name;
    final idx = _cart.lastIndexWhere((e) => e.name == name);
    if (idx < 0) return;
    final item = _cart[idx];
    final note = await _promptNote(item);
    if (note != null && note.isNotEmpty) {
      _applyNoteToLastAdded(note);
    }
  }

  /// Selector de base para un producto combinable (ej. Michelada → cerveza/soda).
  void _pickComposableBase(ProductEntity p) {
    final all = ref.read(productsProvider).valueOrNull ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData groupIcon(String cat) {
      final title = _baseGroupTitle(cat);
      if (title == 'CERVEZA') return Icons.sports_bar_rounded;
      if (title == 'SODA') return Icons.local_drink_rounded;
      return Icons.local_bar_rounded;
    }

    String? selectedNote;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBaseState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkOutline : AppColors.lightOutline,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // ── Encabezado ─────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_bar_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: AppTextStyles.headlineSmall),
                          Text(
                            'Elige la base  ·  ${p.price.toCop}',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Modificadores / Escarchado (opcional) ───────────────
                if (p.defaultNotes.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('MODIFICADOR / ESCARCHADO (OPCIONAL)',
                          style: AppTextStyles.statusBadge
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final note in p.defaultNotes)
                        FilterChip(
                          label: Text(note, style: AppTextStyles.labelSmall),
                          selected: selectedNote == note,
                          onSelected: (sel) {
                            setBaseState(() {
                              selectedNote = sel ? note : null;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Grupos de base ─────────────────────────────────────
                for (final baseCat in p.baseCategories) ...[
                  Row(
                    children: [
                      Icon(groupIcon(baseCat),
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(_baseGroupTitle(baseCat),
                          style: AppTextStyles.statusBadge
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 50,
                    ),
                    itemCount: all
                        .where((x) => x.category == baseCat && x.isAvailable)
                        .length,
                    itemBuilder: (_, i) {
                      final opt = all
                          .where((x) => x.category == baseCat && x.isAvailable)
                          .elementAt(i);
                      return InkWell(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLg),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _addToCart(
                            '${_composedPrefix(p.name)} · ${_baseLabel(opt.name)}',
                            p.price,
                            ProductCategory.standard,
                            note: selectedNote,
                            menuCategory: p.category,
                            subcategory: baseCat,
                          );
                        },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _baseLabel(opt.name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.lightOnSurface,
                                ),
                              ),
                            ),
                            const Icon(Icons.add_rounded,
                                color: AppColors.primary, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  String _baseLabel(String name) => name
      .replaceFirst(RegExp(r'^(Cerveza|Soda|Gaseosa)\s+'), '')
      .replaceFirst(RegExp(r'\s+Sola$'), '')
      .trim();

  /// Nombre compacto de la línea compuesta: "Michelada de Cerveza" → "M. Cerveza"
  /// (así "M. Cerveza · Águila Light" cabe en el tiquete).
  String _composedPrefix(String productName) => productName
      .replaceFirst(RegExp(r'^Michelada\s+(de\s+)?', caseSensitive: false), 'M. ')
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
                              _changeCartQty(e, -1);
                              refresh();
                            },
                            onPlus: () {
                              _changeCartQty(e, 1);
                              refresh();
                            },
                            onNote: () async {
                              final note = await _promptNote(e);
                              if (note != null) {
                                _setCartNote(e, note.isEmpty ? null : note);
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
    final allProducts = ref.read(productsProvider).valueOrNull ?? [];
    final baseName = entry.name.split(' · ').first;
    final product = allProducts
        .where((p) => p.name == entry.name || p.name == baseName)
        .firstOrNull;
    final defaultNotes = product?.defaultNotes ?? const <String>[];

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(entry.name,
              style: AppTextStyles.labelMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (defaultNotes.isNotEmpty) ...[
                  Text(
                    'OPCIONES RÁPIDAS',
                    style: AppTextStyles.statusBadge
                        .copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final n in defaultNotes)
                        ActionChip(
                          label: Text(n, style: AppTextStyles.labelSmall),
                          onPressed: () {
                            setDialogState(() {
                              final current = ctrl.text.trim();
                              if (current.isEmpty) {
                                ctrl.text = n;
                              } else if (!current.contains(n)) {
                                ctrl.text = '$current, $n';
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: ctrl,
                  autofocus: defaultNotes.isEmpty,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Ej: sin hielo, con limón, término medio...',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
              ],
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

                  // Título de sección + conteo (+ precio único si es uniforme).
                  Builder(builder: (context) {
                    final uniform = shown.isNotEmpty &&
                        shown.every((p) => p.price == shown.first.price);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            searching ? 'Resultados' : (_selectedMenuCat ?? ''),
                            style: AppTextStyles.headlineMedium,
                          ),
                        ),
                        if (uniform && shown.length > 1) ...[
                          Text(
                            '${shown.first.price.toCop} c/u  ·  ',
                            style: AppTextStyles.titleSmall
                                .copyWith(color: AppColors.secondaryDark),
                          ),
                        ],
                        Text(
                          '${shown.length} producto${shown.length == 1 ? '' : 's'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  }),
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
                    // Grilla adaptativa: los productos fluyen en varias
                    // columnas. Si toda la sección comparte precio, se muestra
                    // una sola vez en el encabezado (no repetido por tarjeta).
                    Builder(builder: (context) {
                      final uniform = shown.length > 1 &&
                          shown.every((p) => p.price == shown.first.price);
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: uniform ? 68 : 90,
                        ),
                        itemCount: shown.length,
                        itemBuilder: (_, i) => _ProductCard(
                          product: shown[i],
                          showPrice: !uniform,
                          inCartQty: _cart
                              .where((e) =>
                                  e.name == shown[i].name ||
                                  e.name.startsWith('${shown[i].name} ·'))
                              .fold(0, (s, e) => s + e.quantity),
                          isDark: isDark,
                          onAdd: () => _pickProduct(shown[i]),
                          onCustomize: () => _openQuickNoteSheet(shown[i]),
                        ),
                      );
                    }),

                  const SizedBox(height: 14),

                  // ¿Algo fuera del menú?
                  _OutOfMenuCard(isDark: isDark, onTap: _openCustomForm),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Banner modificador rápido (si se añadió un ítem con notas predeterminadas) ──
            if (_lastAddedProduct != null && _lastAddedProduct!.defaultNotes.isNotEmpty)
              _QuickNotesBanner(
                product: _lastAddedProduct!,
                isDark: isDark,
                onNoteTap: (note) => _applyNoteToLastAdded(note),
                onCustomTap: () => _openCustomNoteForLastAdded(),
                onClose: () => setState(() => _lastAddedProduct = null),
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

// ── Product card (grilla compacta) ────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.inCartQty,
    required this.isDark,
    required this.onAdd,
    this.onCustomize,
    this.showPrice = false,
  });

  final ProductEntity product;
  final int inCartQty;
  final bool isDark;
  final VoidCallback onAdd;
  final VoidCallback? onCustomize;

  /// Solo cuando la sección tiene precios mixtos — si el precio es uniforme,
  /// se muestra una vez en el encabezado y las tarjetas quedan limpias.
  final bool showPrice;

  @override
  Widget build(BuildContext context) {
    final selected = inCartQty > 0;

    final noteButton = (product.defaultNotes.isNotEmpty && onCustomize != null)
        ? GestureDetector(
            onTap: onCustomize,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.statusOrange.withOpacity(0.14),
                border: Border.all(color: AppColors.statusOrange.withOpacity(0.5)),
              ),
              child: const Center(
                child: Icon(Icons.tune_rounded,
                    color: AppColors.statusOrange, size: 16),
              ),
            ),
          )
        : const SizedBox.shrink();

    final plusButton = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Center(
        child: selected
            ? Text(
                '$inCartQty',
                style: AppTextStyles.labelMedium.copyWith(
                  color: const Color(0xFF241A05),
                  fontWeight: FontWeight.w800,
                ),
              )
            : const Icon(Icons.add_rounded, color: AppColors.primary, size: 19),
      ),
    );

    final name = Text(
      product.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyMedium.copyWith(
        height: 1.2,
        color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      ),
    );

    return InkWell(
      onTap: onAdd,
      onLongPress: onCustomize,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: showPrice
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: name),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.price.toCop,
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.secondaryDark),
                        ),
                      ),
                      if (product.defaultNotes.isNotEmpty && onCustomize != null)
                        noteButton,
                      plusButton,
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: name),
                  const SizedBox(width: 6),
                  if (product.defaultNotes.isNotEmpty && onCustomize != null)
                    noteButton,
                  plusButton,
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

// ── Banner modificador rápido al pie ──────────────────────────────────────────

class _QuickNotesBanner extends StatelessWidget {
  const _QuickNotesBanner({
    required this.product,
    required this.isDark,
    required this.onNoteTap,
    required this.onCustomTap,
    required this.onClose,
  });

  final ProductEntity product;
  final bool isDark;
  final void Function(String note) onNoteTap;
  final VoidCallback onCustomTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D10) : const Color(0xFFFFF8E7),
        border: Border(
          top: BorderSide(
            color: AppColors.statusOrange.withOpacity(0.4),
          ),
          bottom: BorderSide(
            color: AppColors.statusOrange.withOpacity(0.4),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 14, color: AppColors.statusOrange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Modificar ${product.name}:',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.statusOrange,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: AppColors.statusOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final note in product.defaultNotes)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          isDark ? AppColors.darkSurface : Colors.white,
                      side: BorderSide(
                          color: AppColors.statusOrange.withOpacity(0.5)),
                      label: Text(
                        note,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.statusOrange),
                      ),
                      onPressed: () => onNoteTap(note),
                    ),
                  ),
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.edit_note_rounded,
                      size: 14, color: AppColors.statusOrange),
                  backgroundColor:
                      isDark ? AppColors.darkSurface : Colors.white,
                  side: BorderSide(
                      color: AppColors.statusOrange.withOpacity(0.5)),
                  label: Text(
                    'Libre...',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.statusOrange),
                  ),
                  onPressed: onCustomTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hoja modal de notas rápidas y personalizadas ───────────────────────────────

class _QuickNoteSheet extends StatefulWidget {
  const _QuickNoteSheet({
    required this.product,
    required this.onAdd,
  });

  final ProductEntity product;
  final void Function(int qty, String? note) onAdd;

  @override
  State<_QuickNoteSheet> createState() => _QuickNoteSheetState();
}

class _QuickNoteSheetState extends State<_QuickNoteSheet> {
  final _noteCtrl = TextEditingController();
  final _selectedNotes = <String>{};
  int _qty = 1;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final parts = <String>[..._selectedNotes];
    final custom = _noteCtrl.text.trim();
    if (custom.isNotEmpty && !parts.contains(custom)) {
      parts.add(custom);
    }
    final combined = parts.isEmpty ? null : parts.join(', ');
    widget.onAdd(_qty, combined);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name,
                          style: AppTextStyles.headlineSmall),
                      Text(
                        '${widget.product.price.toCop}  ·  Personalizar',
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
            const SizedBox(height: 14),

            // Selector de cantidad
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cantidad', style: AppTextStyles.titleMedium),
                Row(
                  children: [
                    IconButton(
                      onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
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
              ],
            ),
            const SizedBox(height: 12),

            // Chips táctiles de selección rápida
            if (widget.product.defaultNotes.isNotEmpty) ...[
              Text(
                'MODIFICADORES RÁPIDOS',
                style: AppTextStyles.statusBadge.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final note in widget.product.defaultNotes)
                    FilterChip(
                      label: Text(note, style: AppTextStyles.labelSmall),
                      selected: _selectedNotes.contains(note),
                      onSelected: (sel) {
                        setState(() {
                          if (sel) {
                            _selectedNotes.add(note);
                          } else {
                            _selectedNotes.remove(note);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Campo de nota libre personalizada
            Text(
              'NOTA PERSONALIZADA (OPCIONAL)',
              style: AppTextStyles.statusBadge.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Ej: sin cebolla, término medio, vaso con hielo...',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                _selectedNotes.isEmpty && _noteCtrl.text.trim().isEmpty
                    ? 'Agregar sin notas ($_qty)'
                    : 'Agregar con nota ($_qty)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
