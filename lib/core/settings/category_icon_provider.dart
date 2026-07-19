import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_provider.dart';

/// Íconos elegibles para categorías del menú — lista curada, solo temática de
/// bar/restaurante (nada de emojis). key estable → ícono Material.
const Map<String, IconData> kCategoryIconChoices = {
  'coctel': Icons.local_bar_rounded,
  'cerveza': Icons.sports_bar_rounded,
  'vino': Icons.wine_bar_rounded,
  'botella': Icons.liquor_rounded,
  'gaseosa': Icons.local_drink_rounded,
  'agua': Icons.water_drop_rounded,
  'cafe': Icons.local_cafe_rounded,
  'te': Icons.emoji_food_beverage_rounded,
  'frio': Icons.ac_unit_rounded,
  'paleta': Icons.icecream_rounded,
  'batido': Icons.blender_rounded,
  'fiesta': Icons.celebration_rounded,
  'noche': Icons.nightlife_rounded,
  'comida': Icons.restaurant_rounded,
  'rapida': Icons.fastfood_rounded,
  'hamburguesa': Icons.lunch_dining_rounded,
  'pizza': Icons.local_pizza_rounded,
  'postre': Icons.cake_rounded,
  'picada': Icons.kebab_dining_rounded,
  'mariscos': Icons.set_meal_rounded,
  'desayuno': Icons.bakery_dining_rounded,
  'destacado': Icons.star_rounded,
  'promo': Icons.sell_rounded,
  'otros': Icons.category_rounded,
};

/// Default inteligente cuando la categoría no tiene ícono asignado.
String defaultIconKeyFor(String category) {
  final c = category.toLowerCase();
  if (c.contains('mojito') || c.contains('coctel')) return 'coctel';
  if (c.contains('michelada')) return 'cerveza';
  if (c.contains('fría') || c.contains('fria') || c.contains('cerve')) {
    return 'cerveza';
  }
  if (c.contains('granizado')) return 'frio';
  if (c.contains('gaseosa') || c.contains('soda')) return 'gaseosa';
  if (c.contains('paleta') || c.contains('helado')) return 'paleta';
  if (c.contains('sangría') || c.contains('sangria') || c.contains('vino')) {
    return 'vino';
  }
  if (c.contains('licor') || c.contains('botella') || c.contains('descorche')) {
    return 'botella';
  }
  if (c.contains('agua')) return 'agua';
  if (c.contains('café') || c.contains('cafe')) return 'cafe';
  return 'otros';
}

const String _kCategoryIconsKey = 'thebase_category_icons';

/// Mapa categoría → key de ícono, persistido en SharedPreferences.
class CategoryIconsNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_kCategoryIconsKey);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return const {};
    }
  }

  void setIcon(String category, String iconKey) {
    state = {...state, category: iconKey};
    _persist();
  }

  /// Mantiene el ícono al renombrar la categoría.
  void rename(String oldName, String newName) {
    if (!state.containsKey(oldName)) return;
    final next = {...state};
    next[newName] = next.remove(oldName)!;
    state = next;
    _persist();
  }

  void remove(String category) {
    if (!state.containsKey(category)) return;
    state = {...state}..remove(category);
    _persist();
  }

  void _persist() {
    ref
        .read(sharedPreferencesProvider)
        .setString(_kCategoryIconsKey, jsonEncode(state));
  }
}

final categoryIconsProvider =
    NotifierProvider<CategoryIconsNotifier, Map<String, String>>(
  CategoryIconsNotifier.new,
);

/// Ícono efectivo de una categoría (asignado o default inteligente).
IconData categoryIconFor(Map<String, String> assigned, String category) {
  final key = assigned[category] ?? defaultIconKeyFor(category);
  return kCategoryIconChoices[key] ?? Icons.category_rounded;
}
