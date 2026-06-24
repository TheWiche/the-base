import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── SharedPreferences provider ──────────────────────────────────────────────

/// Initialized in main.dart before runApp and overridden via ProviderScope.
/// Declare here so features can use SharedPreferences without knowing its source.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope. '
    'Call SharedPreferences.getInstance() in main() and override this provider.',
  ),
);

// ── Theme mode key ──────────────────────────────────────────────────────────

const String _kThemeModeKey = 'thebase_theme_mode';

// ── Notifier ─────────────────────────────────────────────────────────────────

/// Persists and restores the user's chosen [ThemeMode] via [SharedPreferences].
///
/// Usage:
///   ```dart
///   // Read current mode
///   final mode = ref.watch(themeModeProvider);
///
///   // Toggle
///   ref.read(themeModeProvider.notifier).toggle();
///
///   // Set explicitly
///   ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
///   ```
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _values = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_kThemeModeKey);
    return _fromString(stored) ?? ThemeMode.dark;
  }

  /// Cycles: dark → light → system → dark.
  void toggle() {
    final next = switch (state) {
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
      ThemeMode.system => ThemeMode.dark,
    };
    setMode(next);
  }

  void setMode(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_kThemeModeKey, mode.name);
  }

  static ThemeMode? _fromString(String? value) {
    if (value == null) return null;
    return _values.where((m) => m.name == value).firstOrNull;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ── Convenience extension ────────────────────────────────────────────────────

extension ThemeModeX on ThemeMode {
  String get label => switch (this) {
        ThemeMode.dark => 'Oscuro',
        ThemeMode.light => 'Claro',
        ThemeMode.system => 'Sistema',
      };

  IconData get icon => switch (this) {
        ThemeMode.dark => Icons.dark_mode_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.system => Icons.brightness_auto_rounded,
      };

  bool get isDark => this == ThemeMode.dark;
  bool get isLight => this == ThemeMode.light;
}
