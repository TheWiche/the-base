import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/bar_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';

/// Pantalla de Ajustes: nombre del bar (encabeza los tiquetes) y tema.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barName = ref.watch(barNameProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Configuración', style: AppTextStyles.headlineSmall)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('NEGOCIO'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_rounded, color: AppColors.primary),
              title: Text('Nombre del bar', style: AppTextStyles.titleMedium),
              subtitle: Text(barName, style: AppTextStyles.bodySmall),
              trailing: const Icon(Icons.edit_rounded, size: 18),
              onTap: () => _editBarName(context, ref, barName),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('APARIENCIA'),
          Card(
            child: Column(
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    groupValue: themeMode,
                    activeColor: AppColors.primary,
                    secondary: Icon(mode.icon, color: AppColors.primary),
                    title: Text(mode.label, style: AppTextStyles.bodyMedium),
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).setMode(v!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'The Base — Billetera del Mesero',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.lightOnSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editBarName(BuildContext context, WidgetRef ref, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nombre del bar'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'MI BAR',
            helperText: 'Aparece en el encabezado de los tiquetes',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null) {
      ref.read(barNameProvider.notifier).setName(result);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.statusBadge.copyWith(color: AppColors.primary),
      ),
    );
  }
}
