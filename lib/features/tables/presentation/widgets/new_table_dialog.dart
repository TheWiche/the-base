import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Diálogo para abrir una nueva mesa con número autoincremental y apodo opcional.
class NewTableDialog extends StatefulWidget {
  const NewTableDialog({
    super.key,
    required this.tableNumber,
    required this.onOpen,
  });

  /// Número asignado automáticamente para la mesa.
  final int tableNumber;

  /// Callback al confirmar con el apodo opcional.
  final Future<void> Function(String? apodo) onOpen;

  @override
  State<NewTableDialog> createState() => _NewTableDialogState();
}

class _NewTableDialogState extends State<NewTableDialog> {
  final _apodoController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _apodoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final apodo = _apodoController.text.trim();
    await widget.onOpen(apodo.isEmpty ? null : apodo);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.table_restaurant_rounded,
            color: AppColors.brand,
            size: AppDimensions.iconLg,
          ),
          const SizedBox(width: AppDimensions.space12),
          Text('Nueva Mesa', style: AppTextStyles.headlineSmall),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Número de mesa asignado ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.space16,
            ),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: AppColors.brand.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.tableNumber}',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.brand,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Mesa asignada automáticamente',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.brand.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space16),

          // ── Apodo opcional ─────────────────────────────────────────
          TextField(
            controller: _apodoController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.bodyLarge,
            decoration: const InputDecoration(
              labelText: 'Apodo (opcional)',
              hintText: 'Ej: Los cumpleañeros',
              prefixIcon: Icon(Icons.label_outline_rounded),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_isSubmitting ? 'Abriendo...' : 'ABRIR MESA'),
        ),
      ],
    );
  }
}
