import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/settings/bar_settings_provider.dart';
import '../../../../core/settings/financial_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/receipt_widgets.dart';

/// Pantalla de Ajustes — estilo tiquete: nombre del bar, base inicial y paso
/// de incremento/decremento configurables, y tema.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barName = ref.watch(barNameProvider);
    final themeMode = ref.watch(themeModeProvider);
    final financial = ref.watch(financialSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('Configuración', style: AppTextStyles.headlineSmall)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ── Ficha del negocio (papel) ──────────────────────────────
          ReceiptPaper(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  barName.toUpperCase(),
                  style: AppTextStyles.receiptTitle.copyWith(color: AppColors.paperInk),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Encabeza tus tiquetes y facturas',
                  style: AppTextStyles.receiptSmall.copyWith(color: AppColors.paperInkSoft),
                  textAlign: TextAlign.center,
                ),
                const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
                _PaperActionRow(
                  icon: Icons.storefront_rounded,
                  label: 'Nombre del bar',
                  value: barName,
                  onTap: () => _editBarName(context, ref, barName),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Base financiera ─────────────────────────────────────────
          _SectionLabel('BASE Y TURNO'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.savings_rounded, color: AppColors.primary),
                  title: Text('Base inicial del turno', style: AppTextStyles.titleMedium),
                  subtitle: Text(financial.baseAmount.toCop, style: AppTextStyles.mono),
                  trailing: const Icon(Icons.edit_rounded, size: 18),
                  onTap: () => _editAmount(
                    context,
                    ref,
                    title: 'Base inicial',
                    current: financial.baseAmount,
                    onSave: (v) {
                      ref.read(financialSettingsProvider.notifier).setBaseAmount(v);
                      AppToast.success(context, 'Base inicial: ${v.toCop}');
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.trending_up_rounded, color: AppColors.primary),
                  title: Text('Paso de incremento/reducción', style: AppTextStyles.titleMedium),
                  subtitle: Text('±${financial.incrementStep.toCop} por solicitud',
                      style: AppTextStyles.mono),
                  trailing: const Icon(Icons.edit_rounded, size: 18),
                  onTap: () => _editAmount(
                    context,
                    ref,
                    title: 'Paso de incremento',
                    current: financial.incrementStep,
                    onSave: (v) {
                      ref.read(financialSettingsProvider.notifier).setIncrementStep(v);
                      AppToast.success(context, 'Paso actualizado: ±${v.toCop}');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Apariencia ──────────────────────────────────────────────
          _SectionLabel('APARIENCIA'),
          Card(
            margin: EdgeInsets.zero,
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
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
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

  Future<void> _editAmount(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int current,
    required void Function(int) onSave,
  }) async {
    final ctrl = TextEditingController(text: current.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(prefixText: '\$ '),
          onSubmitted: (v) => Navigator.of(ctx).pop(int.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(int.tryParse(ctrl.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result > 0) onSave(result);
  }
}

class _PaperActionRow extends StatelessWidget {
  const _PaperActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.receiptBody.copyWith(color: AppColors.paperInk)),
            ),
            Text(value,
                style: AppTextStyles.receiptBodyBold.copyWith(color: AppColors.paperInk)),
            const SizedBox(width: 6),
            Icon(Icons.edit_rounded, size: 14, color: AppColors.paperInkSoft),
          ],
        ),
      ),
    );
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
