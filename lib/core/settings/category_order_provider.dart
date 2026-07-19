import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/product_categories.dart';
import '../theme/theme_provider.dart';

/// Orden de categorías del menú, persistido y editable desde el gestor.
/// Semilla inicial = [kCategoryOrder]. Las categorías nuevas que aparezcan en
/// productos pero no estén en la lista se tratan como "al final".
const String _kCategoryOrderKey = 'thebase_category_order';

class CategoryOrderNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_kCategoryOrderKey);
    if (stored == null) return List<String>.from(kCategoryOrder);
    try {
      final list = (jsonDecode(stored) as List).cast<String>();
      return list.isEmpty ? List<String>.from(kCategoryOrder) : list;
    } catch (_) {
      return List<String>.from(kCategoryOrder);
    }
  }

  void _persist() {
    ref.read(sharedPreferencesProvider).setString(
          _kCategoryOrderKey,
          jsonEncode(state),
        );
  }

  void setOrder(List<String> order) {
    state = List<String>.from(order);
    _persist();
  }

  void add(String category) {
    final c = category.trim();
    if (c.isEmpty || state.contains(c)) return;
    state = [...state, c];
    _persist();
  }

  void remove(String category) {
    if (!state.contains(category)) return;
    state = state.where((c) => c != category).toList();
    _persist();
  }

  void rename(String from, String to) {
    final t = to.trim();
    if (t.isEmpty) return;
    state = state.map((c) => c == from ? t : c).toList();
    _persist();
  }

  /// Índice de orden; categorías desconocidas van al final.
  int indexOf(String category) {
    final i = state.indexOf(category);
    return i == -1 ? 9999 : i;
  }
}

final categoryOrderProvider =
    NotifierProvider<CategoryOrderNotifier, List<String>>(
  CategoryOrderNotifier.new,
);
