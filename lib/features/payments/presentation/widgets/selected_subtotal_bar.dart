import 'package:flutter/material.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/billing_selection.dart';

/// Persistent bottom bar in [BillingScreen].
///
/// Shows:
///   • Count of selected items vs total selectable items.
///   • Live subtotal of the current selection.
///   • "SELECCIONAR TODO" / "QUITAR TODOS" toggle.
///   • "COBRAR" primary CTA (disabled when selection is empty).
class SelectedSubtotalBar extends StatelessWidget {
  const SelectedSubtotalBar({
    super.key,
    required this.selection,
    required this.subtotal,
    required this.selectableCount,
    required this.onCobrar,
    required this.onSelectAll,
    required this.onClearAll,
  });

  final BillingSelection selection;
  final int subtotal;

  /// Number of items that CAN be selected (unpaid, not cancelled).
  final int selectableCount;

  final VoidCallback onCobrar;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  bool get _allSelected => selection.count == selectableCount && selectableCount > 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSelection = !selection.isEmpty;

    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: hasSelection
                  ? AppColors.brand.withOpacity(0.6)
                  : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
              width: hasSelection ? 2.0 : 1.0,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH,
          AppDimensions.space12,
          AppDimensions.pagePaddingH,
          AppDimensions.space12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Summary row ────────────────────────────────────────────
            Row(
              children: [
                // Selected count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSelection
                            ? '${selection.count} de $selectableCount ítems'
                            : 'Ningún ítem seleccionado',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          hasSelection ? subtotal.toCop : '\$ —',
                          key: ValueKey(subtotal),
                          style: AppTextStyles.displaySmall.copyWith(
                            color: hasSelection
                                ? AppColors.brand
                                : (isDark
                                    ? AppColors.darkDisabled
                                    : AppColors.lightDisabled),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Select-all / clear-all toggle
                if (selectableCount > 0)
                  TextButton.icon(
                    onPressed: _allSelected ? onClearAll : onSelectAll,
                    icon: Icon(
                      _allSelected
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      size: AppDimensions.iconSm,
                    ),
                    label: Text(
                      _allSelected ? 'Quitar todos' : 'Seleccionar todo',
                      style: AppTextStyles.labelSmall,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppDimensions.space12),

            // ── COBRAR button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeightLg,
              child: FilledButton.icon(
                onPressed: hasSelection ? onCobrar : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusGreen,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: (isDark
                          ? AppColors.darkOutline
                          : AppColors.lightOutline)
                      .withOpacity(0.5),
                ),
                icon: const Icon(Icons.point_of_sale_rounded),
                label: Text(
                  hasSelection
                      ? 'COBRAR ${subtotal.toCop}'
                      : 'COBRAR SELECCIÓN',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: hasSelection ? Colors.black : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
