import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_provider.dart';

/// Nombre del bar/negocio que encabeza los tiquetes ("MI BAR" por defecto).
/// Persistido en SharedPreferences y editable desde Ajustes.
const String _kBarNameKey = 'thebase_bar_name';
const String kDefaultBarName = 'MI BAR';

class BarNameNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_kBarNameKey)?.trim();
    return (stored == null || stored.isEmpty) ? kDefaultBarName : stored;
  }

  void setName(String name) {
    final clean = name.trim();
    state = clean.isEmpty ? kDefaultBarName : clean;
    ref.read(sharedPreferencesProvider).setString(_kBarNameKey, state);
  }
}

final barNameProvider = NotifierProvider<BarNameNotifier, String>(
  BarNameNotifier.new,
);
