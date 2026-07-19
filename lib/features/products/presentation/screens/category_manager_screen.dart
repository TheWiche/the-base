import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/category_order_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/product_providers.dart';

/// Gestor de categorías: crear, renombrar, eliminar y reordenar.
/// El orden se persiste; renombrar actualiza todos los productos.
class CategoryManagerScreen extends ConsumerWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(categoryOrderProvider);
    final products = ref.watch(productsProvider).valueOrNull ?? [];

    // Categorías = orden guardado + las que existan en productos y falten.
    final fromProducts = <String>{for (final p in products) p.category};
    final categories = <String>[
      ...order,
      ...fromProducts.where((c) => !order.contains(c)),
    ];

    int countIn(String c) => products.where((p) => p.category == c).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Categorías', style: AppTextStyles.headlineSmall),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCategory(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Categoría'),
      ),
      body: categories.isEmpty
          ? Center(
              child: Text('Sin categorías todavía',
                  style: AppTextStyles.bodyLarge),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              itemCount: categories.length,
              onReorder: (oldIndex, newIndex) {
                final list = [...categories];
                if (newIndex > oldIndex) newIndex -= 1;
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                ref.read(categoryOrderProvider.notifier).setOrder(list);
              },
              itemBuilder: (context, i) {
                final cat = categories[i];
                final n = countIn(cat);
                return Card(
                  key: ValueKey(cat),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle_rounded),
                    title: Text(cat, style: AppTextStyles.titleMedium),
                    subtitle: Text('$n producto${n == 1 ? '' : 's'}',
                        style: AppTextStyles.bodySmall),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          onPressed: () => _rename(context, ref, cat),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 20, color: AppColors.statusRed),
                          onPressed: () => _delete(context, ref, cat, n),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, title: 'Nueva categoría');
    if (name != null && name.isNotEmpty) {
      ref.read(categoryOrderProvider.notifier).add(name);
    }
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, String cat) async {
    final name =
        await _promptName(context, title: 'Renombrar categoría', initial: cat);
    if (name == null || name.isEmpty || name == cat) return;
    await ref.read(productRepositoryProvider).renameCategory(cat, name);
    ref.read(categoryOrderProvider.notifier).rename(cat, name);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, String cat, int count) async {
    if (count > 0) {
      AppToast.error(
        context,
        'No puedes eliminar "$cat": tiene $count producto${count == 1 ? '' : 's'}. '
        'Cámbiales la categoría primero.',
      );
      return;
    }
    ref.read(categoryOrderProvider.notifier).remove(cat);
  }

  Future<String?> _promptName(BuildContext context,
      {required String title, String? initial}) {
    final ctrl = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nombre de la categoría'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
  }
}
