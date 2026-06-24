import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../catalog/domain/entities/catalog_product.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../domain/entities/order_item_entity.dart';

/// Bottom sheet para agregar un ítem a la orden de una mesa.
///
/// Flujo principal:
///   1. El mesero selecciona un producto del grid (menú del local).
///   2. La categoría estándar/licor se asigna AUTOMÁTICAMENTE según el producto.
///   3. Se ajusta cantidad, se agrega nota opcional y se confirma.
///
/// El toggle manual de categoría solo aparece para ítems personalizados
/// (cuando el mesero escribe un producto que no está en el menú).
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
  final _formKey   = GlobalKey<FormState>();
  final _namCtrl   = TextEditingController();
  final _pricCtrl  = TextEditingController();
  final _noteCtrl  = TextEditingController();
  final _srchCtrl  = TextEditingController();

  int _quantity = 1;
  ProductCategory _category = ProductCategory.standard;
  bool _isSubmitting = false;
  String? _selectedMenuCat; // null = TODOS
  String _searchQuery = '';
  final _cart = <_CartEntry>[];

  @override
  void dispose() {
    _namCtrl.dispose();
    _pricCtrl.dispose();
    _noteCtrl.dispose();
    _srchCtrl.dispose();
    super.dispose();
  }

  // ── Carrito ───────────────────────────────────────────────────────────────────

  void _addToCart(String name, int price, ProductCategory category, {int qty = 1, String? note}) {
    HapticFeedback.lightImpact();
    setState(() {
      final idx = _cart.indexWhere((e) => e.name == name);
      if (idx >= 0) {
        _cart[idx].quantity += qty;
      } else {
        _cart.add(_CartEntry(name: name, price: price, category: category, quantity: qty, note: note));
      }
    });
  }

  void _removeFromCart(String name) {
    setState(() => _cart.removeWhere((e) => e.name == name));
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

  void _pickProduct(ProductEntity p) {
    if (!p.isAvailable) return;
    _addToCart(p.name, p.price, p.isLiquor ? ProductCategory.liquor : ProductCategory.standard);
  }

  void _pickMichelada(ProductEntity beer, int price) {
    final beerName = beer.name.replaceFirst('Cerveza ', '');
    _addToCart('Michelada $beerName', price, ProductCategory.standard);
  }

  void _pickCatalog(CatalogProduct p) {
    _addToCart(p.name, p.price, p.category);
  }

  // ── Guardar / Enviar ──────────────────────────────────────────────────────────

  // Adds the manually-entered custom item to the cart (sheet stays open).
  void _addFormItemToCart() {
    if (!_formKey.currentState!.validate()) return;
    final price = int.tryParse(_pricCtrl.text.replaceAll('.', ''));
    if (price == null || price <= 0) return;
    final note = _noteCtrl.text.trim();
    _addToCart(
      _namCtrl.text.trim(),
      price,
      _category,
      qty: _quantity,
      note: note.isEmpty ? null : note,
    );
    _namCtrl.clear();
    _pricCtrl.clear();
    _noteCtrl.clear();
    setState(() => _quantity = 1);
  }

  // Submits all cart items at once and closes the sheet.
  void _submitCart() {
    if (_cart.isEmpty) return;
    setState(() => _isSubmitting = true);
    for (final entry in _cart) {
      widget.onAdd(AddItemParams(
        tableSessionId: widget.tableSessionId,
        productName:    entry.name,
        price:          entry.price,
        quantity:       entry.quantity,
        category:       entry.category,
        note:           entry.note,
      ));
    }
    Navigator.of(context).pop();
  }

  Future<void> _saveToCatalog() async {
    final name  = _namCtrl.text.trim();
    final price = int.tryParse(_pricCtrl.text.replaceAll('.', ''));
    if (name.isEmpty || price == null || price <= 0) return;

    await ref.read(catalogProvider.notifier).save(CatalogProduct(
      id:       DateTime.now().millisecondsSinceEpoch.toString(),
      name:     name,
      price:    price,
      category: _category,
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:  Text('"$name" guardado en tu catálogo.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _deleteCatalog(CatalogProduct p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar del catálogo'),
        content: Text('¿Eliminar "${p.name}" del catálogo de acceso rápido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.statusRed),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(catalogProvider.notifier).remove(p.id);
  }

  // ── Build ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final surface      = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final isLiquor     = _category == ProductCategory.liquor;
    final hasContent   = _namCtrl.text.trim().isNotEmpty;
    final cartNames    = _cart.map((e) => e.name).toSet();
    final cartCounts   = Map.fromEntries(_cart.map((e) => MapEntry(e.name, e.quantity)));

    final catalogAsync = ref.watch(catalogProvider);
    final catalog      = catalogAsync.valueOrNull ?? [];

    final menuAsync    = ref.watch(productsProvider);
    final menuAll      = menuAsync.valueOrNull ?? [];
    final menuCats     = ref.watch(productCategoriesProvider);

    // "TODOS" = null para _selectedMenuCat; cualquier otra = filtro de categoría
    final filtered = menuAll.where((p) {
      final matchCat = _selectedMenuCat == null || p.category == _selectedMenuCat;
      final matchQ   = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchQ;
    }).toList();

    final isMicheladasCat = _selectedMenuCat == 'Micheladas';
    final beersForMichelada = isMicheladasCat
        ? menuAll.where((p) => p.category == "Fría's").toList()
        : <ProductEntity>[];
    final micheladaPrice = menuAll
        .where((p) => p.category == 'Micheladas')
        .map((p) => p.price)
        .fold<int?>(null, (prev, p) => prev ?? p) ?? 8000;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
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
            // ── Drag handle ──────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  vertical: AppDimensions.space12,
                ),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
              ),
              child: Row(
                children: [
                  Icon(
                    isLiquor
                        ? Icons.wine_bar_rounded
                        : Icons.add_shopping_cart_rounded,
                    color: isLiquor
                        ? AppColors.statusPurple
                        : AppColors.primary,
                    size: AppDimensions.iconMd,
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: Text(
                      'Agregar a la Mesa',
                      style: AppTextStyles.headlineSmall,
                    ),
                  ),
                  if (hasContent)
                    IconButton(
                      onPressed: _saveToCatalog,
                      tooltip: 'Guardar en catálogo',
                      icon: const Icon(Icons.star_border_rounded),
                      color: AppColors.primary,
                      iconSize: AppDimensions.iconMd,
                    ),
                ],
              ),
            ),
            const Divider(height: AppDimensions.space20),

            // ── Contenido desplazable ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: EdgeInsets.only(
                  left: AppDimensions.pagePaddingH,
                  right: AppDimensions.pagePaddingH,
                  bottom: MediaQuery.of(context).viewInsets.bottom +
                      AppDimensions.space24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── MENÚ DEL LOCAL ──────────────────────────────────────
                      if (menuAll.isNotEmpty) ...[
                        _SectionLabel(
                          label: 'MENÚ DEL LOCAL',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppDimensions.space8),

                        // Buscador
                        TextField(
                          controller: _srchCtrl,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Buscar producto...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _srchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space12,
                              vertical: AppDimensions.space10,
                            ),
                          ),
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
                        ),
                        const SizedBox(height: AppDimensions.space8),

                        // Filtro de categorías (TODOS + categorías del menú)
                        _CategoryTabs(
                          categories: menuCats,
                          selected: _selectedMenuCat,
                          onSelect: (cat) =>
                              setState(() => _selectedMenuCat = cat),
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppDimensions.space10),

                        // Grid de productos (3 columnas)
                        _ProductGrid(
                          products: filtered,
                          cartCounts: cartCounts,
                          onTap: _pickProduct,
                          isDark: isDark,
                        ),

                        // Micheladas: selector de cervezas
                        if (beersForMichelada.isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.space12),
                          _SectionLabel(
                            label: 'CERVEZA PARA MICHELADA',
                            isDark: isDark,
                          ),
                          const SizedBox(height: AppDimensions.space8),
                          _MicheladaChips(
                            beers: beersForMichelada,
                            micheladaPrice: micheladaPrice,
                            onTap: _pickMichelada,
                            cartNames: cartNames,
                            isDark: isDark,
                          ),
                        ],

                        const SizedBox(height: AppDimensions.space16),
                        Divider(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.lightOutlineVariant,
                        ),
                        const SizedBox(height: AppDimensions.space12),
                      ],

                      // ── ACCESO RÁPIDO ────────────────────────────────────────
                      if (catalog.isNotEmpty) ...[
                        _SectionLabel(
                          label: 'ACCESO RÁPIDO',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        _CatalogChips(
                          products: catalog,
                          onTap: _pickCatalog,
                          onLongPress: _deleteCatalog,
                          cartNames: cartNames,
                        ),
                        const SizedBox(height: AppDimensions.space16),
                        Divider(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.lightOutlineVariant,
                        ),
                        const SizedBox(height: AppDimensions.space12),
                      ],

                      // ── CARRITO ACTUAL ────────────────────────────────────────
                      if (_cart.isNotEmpty) ...[
                        _SectionLabel(
                          label: 'EN EL PEDIDO',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        _CartStrip(
                          cart: _cart,
                          onRemove: _removeFromCart,
                          onQtyChange: _changeCartQty,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppDimensions.space16),
                        Divider(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.lightOutlineVariant,
                        ),
                        const SizedBox(height: AppDimensions.space12),
                      ],

                      // ── ÍTEM PERSONALIZADO ────────────────────────────────────
                      _SectionLabel(
                        label: 'ÍTEM PERSONALIZADO',
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      _CategoryToggle(
                        selected: _category,
                        onChanged: (c) => setState(() => _category = c),
                      ),
                      if (isLiquor) ...[
                        const SizedBox(height: AppDimensions.space10),
                        const _LiquorBanner(),
                      ],
                      const SizedBox(height: AppDimensions.space16),
                      TextFormField(
                        controller: _namCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTextStyles.bodyLarge,
                        decoration: InputDecoration(
                          hintText: isLiquor
                              ? 'Ej: Aguardiente 750ml...'
                              : 'Ej: Michelada, Granizado...',
                          prefixIcon: Icon(
                            isLiquor
                                ? Icons.wine_bar_rounded
                                : Icons.local_bar_rounded,
                            color: isLiquor
                                ? AppColors.statusPurple
                                : AppColors.primary,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Ingresa el nombre'
                                : null,
                      ),

                      const SizedBox(height: AppDimensions.space20),

                      // ── PRECIO + CANTIDAD ────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel(
                                  label: 'PRECIO (COP)',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: AppDimensions.space8),
                                TextFormField(
                                  controller: _pricCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _ThousandsFmt(),
                                  ],
                                  style: AppTextStyles.bodyLarge,
                                  decoration: const InputDecoration(
                                    prefixText: '\$ ',
                                    hintText: '0',
                                  ),
                                  validator: (v) {
                                    final raw = v?.replaceAll('.', '') ?? '';
                                    final n   = int.tryParse(raw);
                                    return (n == null || n <= 0)
                                        ? 'Precio inválido'
                                        : null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel(
                                  label: 'CANTIDAD',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: AppDimensions.space8),
                                _QuantityStepper(
                                  value: _quantity,
                                  onChanged: (q) =>
                                      setState(() => _quantity = q),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.space20),

                      // ── NOTA OPCIONAL ────────────────────────────────────────
                      _SectionLabel(label: 'NOTA (opcional)', isDark: isDark),
                      const SizedBox(height: AppDimensions.space8),
                      TextFormField(
                        controller: _noteCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 2,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Ej: sin hielo, con limón...',
                          prefixIcon: Icon(Icons.sticky_note_2_rounded),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.space16),

                      // ── Botón AÑADIR AL CARRITO ──────────────────────────────
                      if (hasContent) ...[
                        SizedBox(
                          width: double.infinity,
                          height: AppDimensions.buttonHeightMd,
                          child: OutlinedButton.icon(
                            onPressed: _addFormItemToCart,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isLiquor
                                    ? AppColors.statusPurple
                                    : AppColors.primary,
                                width: 1.5,
                              ),
                              foregroundColor: isLiquor
                                  ? AppColors.statusPurple
                                  : AppColors.primary,
                            ),
                            icon: Icon(
                              isLiquor
                                  ? Icons.wine_bar_rounded
                                  : Icons.add_shopping_cart_rounded,
                            ),
                            label: Text(
                              isLiquor
                                  ? 'AÑADIR LICOR AL CARRITO'
                                  : 'AÑADIR AL CARRITO',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isLiquor
                                    ? AppColors.statusPurple
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.space32),
                    ],
                  ),
                ),
              ),
            ),

            // ── CONFIRMAR PEDIDO (sticky footer) ──────────────────────────────
            if (_cart.isNotEmpty)
              _CartConfirmBar(
                cart: _cart,
                isSubmitting: _isSubmitting,
                onConfirm: _submitCart,
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    final s   = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Label de sección ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.statusBadge.copyWith(
        color: isDark
            ? AppColors.darkOnSurfaceVariant
            : AppColors.lightOnSurfaceVariant,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ── Filtro de categorías con "TODOS" ─────────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  final List<String> categories;
  final String? selected;   // null = TODOS
  final void Function(String?) onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final all = <String?>[ null, ...categories ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: all.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.space6),
        itemBuilder: (_, i) {
          final cat        = all[i];
          final isSelected = cat == selected;
          final label      = cat ?? 'TODOS';

          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkOutline
                          : AppColors.lightOutline),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Grid de productos (3 columnas) ────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.cartCounts,
    required this.onTap,
    required this.isDark,
  });

  final List<ProductEntity> products;
  final Map<String, int> cartCounts;
  final void Function(ProductEntity) onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
        child: Center(
          child: Text(
            'Sin productos en esta categoría.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppDimensions.space8,
        mainAxisSpacing: AppDimensions.space8,
        childAspectRatio: 0.95,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p       = products[i];
        final count   = cartCounts[p.name] ?? 0;
        final inCart  = count > 0;
        final isAvail = p.isAvailable;
        final accent  = p.isLiquor ? AppColors.statusPurple : AppColors.secondary;
        final dimColor = isDark ? AppColors.darkDisabled : AppColors.lightDisabled;
        final color   = isAvail ? accent : dimColor;

        return GestureDetector(
          onTap: isAvail ? () => onTap(p) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: inCart
                  ? color.withOpacity(0.18)
                  : (isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: inCart
                    ? color
                    : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
                width: inCart ? 2 : 1,
              ),
            ),
            child: Opacity(
              opacity: isAvail ? 1.0 : 0.45,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          inCart
                              ? Icons.check_circle_rounded
                              : (p.isLiquor
                                  ? Icons.wine_bar_rounded
                                  : Icons.local_drink_rounded),
                          color: color,
                          size: 16,
                        ),
                        const Spacer(),
                        if (inCart)
                          // Count badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            ),
                            child: Text(
                              '$count',
                              style: AppTextStyles.statusBadge.copyWith(
                                fontSize: 9,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else if (p.isLiquor)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.statusPurple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LICOR',
                              style: AppTextStyles.statusBadge.copyWith(
                                fontSize: 7,
                                color: AppColors.statusPurple,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    Expanded(
                      child: Text(
                        p.name,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                          fontWeight: inCart ? FontWeight.w700 : FontWeight.w500,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    if (!isAvail)
                      Text(
                        'AGOTADO',
                        style: AppTextStyles.statusBadge.copyWith(
                          fontSize: 8,
                          color: AppColors.statusRed,
                        ),
                      )
                    else
                      Text(
                        '\$${_fmt(p.price)}',
                        style: AppTextStyles.mono.copyWith(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _fmt(int n) {
    final s   = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Catálogo de acceso rápido (chips) ────────────────────────────────────────

class _CatalogChips extends StatelessWidget {
  const _CatalogChips({
    required this.products,
    required this.onTap,
    required this.onLongPress,
    required this.cartNames,
  });

  final List<CatalogProduct> products;
  final void Function(CatalogProduct) onTap;
  final void Function(CatalogProduct) onLongPress;
  final Set<String> cartNames;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.space8),
        itemBuilder: (_, i) {
          final p          = products[i];
          final color      = p.isLiquor
              ? AppColors.statusPurple
              : AppColors.secondary;
          final isSelected = cartNames.contains(p.name);

          return GestureDetector(
            onTap: () => onTap(p),
            onLongPress: () => onLongPress(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              constraints:
                  const BoxConstraints(minWidth: 80, maxWidth: 140),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space10,
                vertical: AppDimensions.space8,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(isSelected ? 0.2 : 0.07),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isSelected
                      ? color
                      : color.withOpacity(0.4),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : (p.isLiquor
                                ? Icons.wine_bar_rounded
                                : Icons.local_bar_rounded),
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          p.name,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurface
                                : AppColors.lightOnSurface,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${_fmt(p.price)}',
                    style: AppTextStyles.mono.copyWith(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmt(int n) {
    final s   = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Toggle de categoría manual (solo para ítems custom) ──────────────────────

class _CategoryToggle extends StatelessWidget {
  const _CategoryToggle({required this.selected, required this.onChanged});

  final ProductCategory selected;
  final void Function(ProductCategory) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CatOption(
          label: 'ESTÁNDAR',
          icon: Icons.local_bar_rounded,
          color: AppColors.secondary,
          isSelected: selected == ProductCategory.standard,
          onTap: () => onChanged(ProductCategory.standard),
        ),
        const SizedBox(width: AppDimensions.space12),
        _CatOption(
          label: 'LICOR',
          icon: Icons.wine_bar_rounded,
          color: AppColors.statusPurple,
          isSelected: selected == ProductCategory.liquor,
          onTap: () {
            HapticFeedback.mediumImpact();
            onChanged(ProductCategory.liquor);
          },
        ),
      ],
    );
  }
}

class _CatOption extends StatelessWidget {
  const _CatOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: AppDimensions.tapTargetLg,
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isSelected ? color : inactiveColor.withOpacity(0.5),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? color : inactiveColor,
                  size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? color : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Banner info licor ─────────────────────────────────────────────────────────

class _LiquorBanner extends StatelessWidget {
  const _LiquorBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.statusPurple.withOpacity(0.09),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.statusPurple.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.statusPurple, size: 18),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(
              'El costo se suma a tu deuda con el local.\n'
              'No descuenta de tu saldo disponible.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.statusPurple),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Selector de cervezas para michelada ───────────────────────────────────────

class _MicheladaChips extends StatelessWidget {
  const _MicheladaChips({
    required this.beers,
    required this.micheladaPrice,
    required this.onTap,
    required this.cartNames,
    required this.isDark,
  });

  final List<ProductEntity> beers;
  final int micheladaPrice;
  final void Function(ProductEntity, int) onTap;
  final Set<String> cartNames;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.statusBlue;

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: beers.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.space8),
        itemBuilder: (_, i) {
          final beer       = beers[i];
          final isAvail    = beer.isAvailable;
          final chipColor  = isAvail
              ? color
              : (isDark ? AppColors.darkDisabled : AppColors.lightDisabled);
          final beerName   = beer.name.replaceFirst('Cerveza ', '');
          final isSelected = cartNames.contains('Michelada $beerName');

          return GestureDetector(
            onTap: isAvail ? () => onTap(beer, micheladaPrice) : null,
            child: Opacity(
              opacity: isAvail ? 1.0 : 0.4,
              child: Container(
                constraints:
                    const BoxConstraints(minWidth: 80, maxWidth: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space10,
                  vertical: AppDimensions.space8,
                ),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(isSelected ? 0.2 : 0.07),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? chipColor
                        : chipColor.withOpacity(0.4),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.sports_bar_rounded,
                          size: 12,
                          color: chipColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Michelada $beerName',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkOnSurface
                                  : AppColors.lightOnSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (!isAvail)
                      Text('AGOTADO',
                          style: AppTextStyles.statusBadge.copyWith(
                              fontSize: 8, color: AppColors.statusRed))
                    else
                      Text(
                        '\$${_fmt(micheladaPrice)}',
                        style: AppTextStyles.mono.copyWith(
                          fontSize: 11,
                          color: chipColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmt(int n) {
    final s   = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Stepper de cantidad ───────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, required this.onChanged});
  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: AppDimensions.inputHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      child: Row(
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Text(
              '$value',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: SizedBox(
        width: 44,
        height: AppDimensions.inputHeight,
        child: Icon(
          icon,
          color: onTap != null ? AppColors.primary : AppColors.darkDisabled,
          size: AppDimensions.iconMd,
        ),
      ),
    );
  }
}

// ── Modelo de ítem en carrito ─────────────────────────────────────────────────

class _CartEntry {
  _CartEntry({
    required this.name,
    required this.price,
    required this.category,
    this.quantity = 1,
    this.note,
  });

  final String name;
  final int price;
  final ProductCategory category;
  int quantity;
  final String? note;
}

// ── Strip de carrito (lista compacta con controles de cantidad) ───────────────

class _CartStrip extends StatelessWidget {
  const _CartStrip({
    required this.cart,
    required this.onRemove,
    required this.onQtyChange,
    required this.isDark,
  });

  final List<_CartEntry> cart;
  final void Function(String name) onRemove;
  final void Function(String name, int delta) onQtyChange;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in cart) _CartRow(
          entry: entry,
          onRemove: () => onRemove(entry.name),
          onDecrease: () => onQtyChange(entry.name, -1),
          onIncrease: () => onQtyChange(entry.name, 1),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.entry,
    required this.onRemove,
    required this.onDecrease,
    required this.onIncrease,
    required this.isDark,
  });

  final _CartEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isLiquor = entry.category == ProductCategory.liquor;
    final color = isLiquor ? AppColors.statusPurple : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Row(
        children: [
          Icon(
            isLiquor ? Icons.wine_bar_rounded : Icons.local_drink_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '\$${_fmt(entry.price * entry.quantity)}',
                  style: AppTextStyles.mono.copyWith(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Qty stepper inline
          _MiniStepper(
            qty: entry.quantity,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
            tooltip: 'Quitar del pedido',
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
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

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({required this.qty, required this.onDecrease, required this.onIncrease});
  final int qty;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniBtn(icon: Icons.remove_rounded, onTap: onDecrease, isDark: isDark),
        SizedBox(
          width: 28,
          child: Text(
            '$qty',
            style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        _MiniBtn(icon: Icons.add_rounded, onTap: onIncrease, isDark: isDark),
      ],
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.icon, required this.onTap, required this.isDark});
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          ),
        ),
        child: Icon(icon, size: 14,
            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
      ),
    );
  }
}

// ── Barra de confirmación del carrito (footer sticky) ────────────────────────

class _CartConfirmBar extends StatelessWidget {
  const _CartConfirmBar({
    required this.cart,
    required this.isSubmitting,
    required this.onConfirm,
    required this.isDark,
  });

  final List<_CartEntry> cart;
  final bool isSubmitting;
  final VoidCallback onConfirm;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final totalItems = cart.fold<int>(0, (sum, e) => sum + e.quantity);
    final totalAmount = cart.fold<int>(0, (sum, e) => sum + e.price * e.quantity);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space12,
        AppDimensions.pagePaddingH,
        MediaQuery.of(context).padding.bottom + AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppDimensions.buttonHeightLg,
        child: FilledButton.icon(
          onPressed: isSubmitting ? null : () {
            HapticFeedback.mediumImpact();
            onConfirm();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Badge(
                  label: Text('$totalItems'),
                  backgroundColor: Colors.white,
                  textColor: AppColors.primary,
                  child: const Icon(Icons.check_circle_rounded),
                ),
          label: Text(
            'CONFIRMAR PEDIDO · \$${_fmt(totalAmount)}',
            style: AppTextStyles.labelLarge,
          ),
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

// ── Formateador de miles ──────────────────────────────────────────────────────

class _ThousandsFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final digits = next.text.replaceAll('.', '');
    if (digits.isEmpty) return next.copyWith(text: '');
    final n = int.tryParse(digits);
    if (n == null) return old;
    final s   = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    final formatted = buf.toString();
    return next.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
