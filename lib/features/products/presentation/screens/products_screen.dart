import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_providers.dart';

/// Menú — administración completa de productos.
///
/// CRUD: crear (FAB), editar (tap en el ítem), eliminar (dentro del editor),
/// cambiar precio, categoría y subcategoría, marcar licor. Además el toggle de
/// Agotado (isAvailable). Los productos persisten entre turnos.
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

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
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          productsAsync.maybeWhen(
            data: (products) {
              final agotadoCount = products.where((p) => !p.isAvailable).length;
              if (agotadoCount == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: AppDimensions.space16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.statusRed.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      border:
                          Border.all(color: AppColors.statusRed.withOpacity(0.5)),
                    ),
                    child: Text(
                      '$agotadoCount AGOTADO${agotadoCount > 1 ? 'S' : ''}',
                      style: AppTextStyles.statusBadge
                          .copyWith(color: AppColors.statusRed),
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_product',
        onPressed: () => _openEditor(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Producto'),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (products) {
          if (products.isEmpty) return _EmptyState(onCreate: () => _openEditor(context, ref, null));
          return _ProductList(products: products, onEdit: (p) => _openEditor(context, ref, p));
        },
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, ProductEntity? existing) {
    final products = ref.read(productsProvider).valueOrNull ?? [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProductEditorSheet(existing: existing, allProducts: products),
    );
  }
}

// ── Product list (grouped by category) ───────────────────────────────────────

class _ProductList extends ConsumerWidget {
  const _ProductList({required this.products, required this.onEdit});

  final List<ProductEntity> products;
  final void Function(ProductEntity) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = <String, List<ProductEntity>>{};
    for (final p in products) {
      (grouped[p.category] ??= []).add(p);
    }
    final categories = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: categories.length,
      itemBuilder: (_, ci) {
        final category = categories[ci];
        final items = grouped[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CategoryHeader(
              category: category,
              isLiquor: items.first.isLiquor,
              availableCount: items.where((p) => p.isAvailable).length,
              total: items.length,
            ),
            ...items.map(
              (product) => _ProductTile(
                key: ValueKey(product.id),
                product: product,
                onEdit: () => onEdit(product),
                onToggle: () async {
                  final result = await ref
                      .read(toggleAvailabilityUseCaseProvider)
                      .call(product.id);
                  if (result.isErr && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Error: ${(result as Err).failure.message}'),
                        backgroundColor: AppColors.statusRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Category header ───────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.category,
    required this.isLiquor,
    required this.availableCount,
    required this.total,
  });

  final String category;
  final bool isLiquor;
  final int availableCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isLiquor ? AppColors.statusPurple : AppColors.brand;

    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.space16),
      padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH,
          AppDimensions.space8, AppDimensions.pagePaddingH, AppDimensions.space8),
      color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      child: Row(
        children: [
          Icon(isLiquor ? Icons.wine_bar_rounded : Icons.local_bar_rounded,
              color: color, size: AppDimensions.iconSm),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(category.toUpperCase(),
                style: AppTextStyles.statusBadge.copyWith(color: color)),
          ),
          Text(
            '$availableCount / $total disponibles',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product tile ──────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    super.key,
    required this.product,
    required this.onToggle,
    required this.onEdit,
  });

  final ProductEntity product;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAvailable = product.isAvailable;
    final nameColor = isAvailable
        ? (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)
        : (isDark ? AppColors.darkDisabled : AppColors.lightDisabled);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkOutlineVariant
                : AppColors.lightOutlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.space4),
        title: Row(
          children: [
            Expanded(
              child: Text(product.name,
                  style: AppTextStyles.bodyMedium.copyWith(color: nameColor)),
            ),
            if (product.subcategory != null) ...[
              const SizedBox(width: AppDimensions.space8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(product.subcategory!,
                    style: AppTextStyles.statusBadge
                        .copyWith(color: AppColors.brand, fontSize: 9)),
              ),
            ],
            if (!isAvailable) ...[
              const SizedBox(width: AppDimensions.space8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.statusRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border:
                      Border.all(color: AppColors.statusRed.withOpacity(0.5)),
                ),
                child: Text('AGOTADO',
                    style: AppTextStyles.statusBadge
                        .copyWith(color: AppColors.statusRed, fontSize: 9)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '\$ ${_fmt(product.price)}',
          style: AppTextStyles.mono.copyWith(
            fontSize: 12,
            color: isAvailable
                ? (product.isLiquor
                    ? AppColors.statusPurple
                    : AppColors.statusGreen)
                : (isDark ? AppColors.darkDisabled : AppColors.lightDisabled),
          ),
        ),
        trailing: Switch(
          value: isAvailable,
          onChanged: (_) => onToggle(),
          activeColor: AppColors.statusGreen,
          inactiveThumbColor:
              isDark ? AppColors.darkDisabled : AppColors.lightDisabled,
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
  late final TextEditingController _category;
  late final TextEditingController _subcategory;
  late bool _isLiquor;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _price = TextEditingController(text: e == null ? '' : e.price.toString());
    _category = TextEditingController(text: e?.category ?? '');
    _subcategory = TextEditingController(text: e?.subcategory ?? '');
    _isLiquor = e?.isLiquor ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _category.dispose();
    _subcategory.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>{
      for (final p in widget.allProducts) p.category,
    }.toList()
      ..sort();
    final subcategories = <String>{
      for (final p in widget.allProducts)
        if (p.category == _category.text && p.subcategory != null) p.subcategory!,
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
              TextFormField(
                controller: _category,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Categoría'),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              if (categories.isNotEmpty)
                _SuggestionChips(
                  values: categories,
                  onTap: (v) => setState(() => _category.text = v),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subcategory,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Subcategoría (opcional)',
                  hintText: 'Ej: Cerveza, Soda',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (subcategories.isNotEmpty)
                _SuggestionChips(
                  values: subcategories,
                  onTap: (v) => setState(() => _subcategory.text = v),
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
    setState(() => _saving = true);
    final repo = ref.read(productRepositoryProvider);
    final name = _name.text.trim();
    final price = int.parse(_price.text);
    final category = _category.text.trim();
    final sub = _subcategory.text.trim();

    final result = _isEdit
        ? await repo.updateProduct(
            id: widget.existing!.id,
            name: name,
            price: price,
            category: category,
            subcategory: sub.isEmpty ? null : sub,
            isLiquor: _isLiquor,
          )
        : await repo.addProduct(
            name: name,
            price: price,
            category: category,
            subcategory: sub.isEmpty ? null : sub,
            isLiquor: _isLiquor,
          );

    if (!mounted) return;
    if (result.isErr) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as Err).failure.message),
          backgroundColor: AppColors.statusRed,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as Err).failure.message),
          backgroundColor: AppColors.statusRed,
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.values, required this.onTap});

  final List<String> values;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: values
            .map((v) => ActionChip(
                  label: Text(v, style: AppTextStyles.labelSmall),
                  onPressed: () => onTap(v),
                  visualDensity: VisualDensity.compact,
                ))
            .toList(),
      ),
    );
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
