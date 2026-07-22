import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/settings/category_icon_provider.dart';
import '../../../../core/settings/category_order_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_providers.dart';
import 'category_manager_screen.dart';

/// Menú — administración completa de productos.
///
/// CRUD: crear (FAB), editar (tap en el ítem), eliminar (dentro del editor),
/// cambiar precio, categoría y subcategoría, marcar licor. Además el toggle de
/// Agotado (isAvailable). Los productos persisten entre turnos.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _srchCtrl = TextEditingController();
  String _search = '';
  String? _selectedCat; // null = Todas

  @override
  void dispose() {
    _srchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(productsProvider);
    final icons = ref.watch(categoryIconsProvider);
    final order = ref.watch(categoryOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Menú', style: AppTextStyles.headlineSmall),
            Text(
              'Crea, edita y marca agotados',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          // Acceso claro al gestor de categorías, con etiqueta.
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space12),
            child: FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CategoryManagerScreen(),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.category_rounded, size: 18),
              label: Text('Categorías', style: AppTextStyles.labelMedium),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_product',
        onPressed: () => _openEditor(null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Producto'),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (products) {
          if (products.isEmpty) {
            return _EmptyState(onCreate: () => _openEditor(null));
          }

          // Categorías en el orden configurado.
          final present = <String>{for (final p in products) p.category};
          final categories = <String>[
            ...order.where(present.contains),
            ...present.where((c) => !order.contains(c)),
          ];

          final searching = _search.trim().isNotEmpty;
          final shown = products.where((p) {
            if (searching) {
              return p.name.toLowerCase().contains(_search.toLowerCase());
            }
            return _selectedCat == null || p.category == _selectedCat;
          }).toList();

          final agotadoCount =
              products.where((p) => !p.isAvailable).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Buscador + badge agotados ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _srchCtrl,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Buscar en el menú...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () {
                                    _srchCtrl.clear();
                                    setState(() => _search = '');
                                  },
                                )
                              : null,
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    if (agotadoCount > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.statusRed.withOpacity(0.14),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Text(
                          '$agotadoCount',
                          style: AppTextStyles.statusBadge
                              .copyWith(color: AppColors.statusRed),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Chips de categoría con ícono ─────────────────────
              if (!searching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MenuCatChip(
                        label: 'Todas',
                        icon: Icons.apps_rounded,
                        selected: _selectedCat == null,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedCat = null),
                      ),
                      for (final cat in categories)
                        _MenuCatChip(
                          label: cat,
                          icon: categoryIconFor(icons, cat),
                          selected: _selectedCat == cat,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedCat = cat),
                        ),
                    ],
                  ),
                ),

              // ── Grilla de productos ──────────────────────────────
              Expanded(
                child: shown.isEmpty
                    ? Center(
                        child: Text('Sin resultados.',
                            style: AppTextStyles.bodyMedium))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 116,
                        ),
                        itemCount: shown.length,
                        itemBuilder: (_, i) => _ProductCard(
                          key: ValueKey(shown[i].id),
                          product: shown[i],
                          isDark: isDark,
                          onTap: () => _openEditor(shown[i]),
                          onToggle: () => _toggle(shown[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggle(ProductEntity product) async {
    final result =
        await ref.read(toggleAvailabilityUseCaseProvider).call(product.id);
    if (!mounted) return;
    if (result.isErr) {
      AppToast.error(context, (result as Err).failure.message);
      return;
    }
    // Toggle es su propia inversa: "Deshacer" solo vuelve a llamar al mismo
    // use case sobre el mismo id — invierte lo que quede en ese momento.
    final nowAvailable = !product.isAvailable;
    AppToast.success(
      context,
      nowAvailable
          ? '${product.name}: disponible de nuevo'
          : '${product.name}: marcado agotado',
      actionLabel: 'Deshacer',
      onAction: () async {
        final undo =
            await ref.read(toggleAvailabilityUseCaseProvider).call(product.id);
        if (undo.isErr && mounted) {
          AppToast.error(context, (undo as Err).failure.message);
        }
      },
    );
  }

  void _openEditor(ProductEntity? existing) {
    final products = ref.read(productsProvider).valueOrNull ?? [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _ProductEditorSheet(existing: existing, allProducts: products),
    );
  }
}

// ── Category chip (Menú) ──────────────────────────────────────────────────────

class _MenuCatChip extends StatelessWidget {
  const _MenuCatChip({
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
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

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    super.key,
    required this.product,
    required this.isDark,
    required this.onTap,
    required this.onToggle,
  });

  final ProductEntity product;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final available = product.isAvailable;
    final nameColor = available
        ? (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)
        : (isDark ? AppColors.darkDisabled : AppColors.lightDisabled);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: available
                ? (isDark ? AppColors.darkOutline : AppColors.lightOutline)
                : AppColors.statusRed.withOpacity(0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  height: 1.25,
                  color: nameColor,
                  decoration:
                      available ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.price.toCop,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: available
                          ? (product.isLiquor
                              ? AppColors.statusPurple
                              : AppColors.secondaryDark)
                          : (isDark
                              ? AppColors.darkDisabled
                              : AppColors.lightDisabled),
                    ),
                  ),
                ),
                if (product.subcategory != null)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.subcategory!,
                      style: AppTextStyles.statusBadge.copyWith(
                          color: AppColors.primary, fontSize: 8.5),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                Text(
                  available ? 'Disponible' : 'AGOTADO',
                  style: AppTextStyles.statusBadge.copyWith(
                    fontSize: 9,
                    color: available
                        ? AppColors.statusGreen
                        : AppColors.statusRed,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 28,
                  child: Transform.scale(
                    scale: 0.72,
                    child: Switch(
                      value: available,
                      onChanged: (_) => onToggle(),
                      activeColor: AppColors.statusGreen,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
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

// ── Product editor (crear / editar / eliminar) ───────────────────────────────

class _ProductEditorSheet extends ConsumerStatefulWidget {
  const _ProductEditorSheet({required this.existing, required this.allProducts});

  final ProductEntity? existing;
  final List<ProductEntity> allProducts;

  @override
  ConsumerState<_ProductEditorSheet> createState() => _ProductEditorSheetState();
}

class _ProductEditorSheetState extends ConsumerState<_ProductEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  String? _selectedCategory;
  String? _selectedSubcategory;
  late bool _isLiquor;
  late bool _isComposable;
  late Set<String> _baseCategories;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _price = TextEditingController(text: e == null ? '' : e.price.toString());
    _selectedCategory = e?.category;
    _selectedSubcategory = e?.subcategory;
    _isLiquor = e?.isLiquor ?? false;
    _isComposable = e?.isComposable ?? false;
    _baseCategories = {...?e?.baseCategories};
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  /// Prompt genérico para crear un nombre nuevo (categoría / subcategoría).
  Future<String?> _promptNew(String title) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nombre'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Crear')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lista viva: orden configurado + categorías presentes en productos.
    final order = ref.watch(categoryOrderProvider);
    final fromProducts = <String>{for (final p in widget.allProducts) p.category};
    final categories = <String>[
      ...order,
      ...fromProducts.where((c) => !order.contains(c)),
    ];
    final subcategories = <String>{
      for (final p in widget.allProducts)
        if (p.category == _selectedCategory && p.subcategory != null)
          p.subcategory!,
      if (_selectedSubcategory != null) _selectedSubcategory!,
    }.toList()
      ..sort();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkOutline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(_isEdit ? 'Editar producto' : 'Nuevo producto',
                  style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Precio', prefixText: '\$ '),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n <= 0) ? 'Precio inválido' : null;
                },
              ),
              const SizedBox(height: 12),
              // ── Categoría: lista viva + crear nueva al vuelo ─────────
              Text('Categoría',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final c in categories)
                    ChoiceChip(
                      label: Text(c, style: AppTextStyles.labelSmall),
                      selected: _selectedCategory == c,
                      onSelected: (_) => setState(() {
                        _selectedCategory = c;
                        _selectedSubcategory = null;
                      }),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 16),
                    label: Text('Nueva', style: AppTextStyles.labelSmall),
                    onPressed: () async {
                      final name = await _promptNew('Nueva categoría');
                      if (name == null || name.isEmpty) return;
                      ref.read(categoryOrderProvider.notifier).add(name);
                      setState(() {
                        _selectedCategory = name;
                        _selectedSubcategory = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Subcategoría (opcional): existentes + crear nueva ────
              Text('Subcategoría (opcional)',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: Text('Ninguna', style: AppTextStyles.labelSmall),
                    selected: _selectedSubcategory == null,
                    onSelected: (_) =>
                        setState(() => _selectedSubcategory = null),
                  ),
                  for (final s in subcategories)
                    ChoiceChip(
                      label: Text(s, style: AppTextStyles.labelSmall),
                      selected: _selectedSubcategory == s,
                      onSelected: (_) =>
                          setState(() => _selectedSubcategory = s),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 16),
                    label: Text('Nueva', style: AppTextStyles.labelSmall),
                    onPressed: () async {
                      final name = await _promptNew('Nueva subcategoría');
                      if (name == null || name.isEmpty) return;
                      setState(() => _selectedSubcategory = name);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isLiquor,
                onChanged: (v) => setState(() => _isLiquor = v),
                activeColor: AppColors.statusPurple,
                title: Text('Es licor (botella)', style: AppTextStyles.bodyMedium),
                subtitle: Text(
                  'Suma a la deuda del local, no al saldo',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isComposable,
                onChanged: (v) => setState(() => _isComposable = v),
                activeColor: AppColors.primary,
                title: Text('Es combinable (elige base)',
                    style: AppTextStyles.bodyMedium),
                subtitle: Text(
                  'Ej. Michelada: al agregar se elige cerveza o soda',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ),
              if (_isComposable) ...[
                const SizedBox(height: 4),
                Text('Categorías-base',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: categories
                      .where((c) => c != _selectedCategory)
                      .map((c) => FilterChip(
                            label: Text(c, style: AppTextStyles.labelSmall),
                            selected: _baseCategories.contains(c),
                            onSelected: (sel) => setState(() {
                              if (sel) {
                                _baseCategories.add(c);
                              } else {
                                _baseCategories.remove(c);
                              }
                            }),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(_isEdit ? 'Guardar cambios' : 'Crear producto'),
              ),
              if (_isEdit) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _saving ? null : _delete,
                  style: TextButton.styleFrom(foregroundColor: AppColors.statusRed),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar producto'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final category = _selectedCategory?.trim() ?? '';
    if (category.isEmpty) {
      AppToast.error(context, 'Elige o crea una categoría.');
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(productRepositoryProvider);
    final name = _name.text.trim();
    final price = int.parse(_price.text);
    final sub = _selectedSubcategory?.trim() ?? '';

    final baseCats = _isComposable ? _baseCategories.toList() : <String>[];
    final result = _isEdit
        ? await repo.updateProduct(
            id: widget.existing!.id,
            name: name,
            price: price,
            category: category,
            subcategory: sub.isEmpty ? null : sub,
            isLiquor: _isLiquor,
            isComposable: _isComposable,
            baseCategories: baseCats,
          )
        : await repo.addProduct(
            name: name,
            price: price,
            category: category,
            subcategory: sub.isEmpty ? null : sub,
            isLiquor: _isLiquor,
            isComposable: _isComposable,
            baseCategories: baseCats,
          );

    if (!mounted) return;
    if (result.isErr) {
      setState(() => _saving = false);
      AppToast.error(context, (result as Err).failure.message);
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${widget.existing!.name}" del menú?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.statusRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    final result =
        await ref.read(productRepositoryProvider).deleteProduct(widget.existing!.id);
    if (!mounted) return;
    if (result.isErr) {
      setState(() => _saving = false);
      AppToast.error(context, (result as Err).failure.message);
      return;
    }
    Navigator.of(context).pop();
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 64, color: AppColors.brand.withOpacity(0.3)),
          const SizedBox(height: AppDimensions.space16),
          Text('Menú vacío',
              style: AppTextStyles.headlineMedium.copyWith(color: AppColors.brand)),
          const SizedBox(height: AppDimensions.space8),
          Text('Crea tu primer producto con el botón +.',
              style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.space16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Producto'),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Text('Error cargando menú: $error',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.statusRed),
            textAlign: TextAlign.center),
      ),
    );
  }
}
