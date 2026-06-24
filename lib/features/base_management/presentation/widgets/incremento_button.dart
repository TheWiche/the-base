import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Giant primary CTA button for requesting a $100,000 base increase.
///
/// Design requirements:
///   • 64dp minimum height — safe for wet / gloved hands.
///   • Brand amber color — instantly recognizable as the primary action.
///   • Haptic feedback on tap — confirms the touch in noisy environments.
///   • [isLoading] replaces the label with a spinner during async work.
///   • [isEnabled] dims the button when the shift is not yet initialized.
class IncrementoButton extends StatelessWidget {
  const IncrementoButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: AppDimensions.tapTargetLg,
      child: AnimatedOpacity(
        opacity: canTap ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: InkWell(
            onTap: canTap
                ? () {
                    HapticFeedback.mediumImpact();
                    onPressed();
                  }
                : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            splashColor: Colors.white24,
            highlightColor: Colors.white12,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1A0A00),
                        ),
                      ),
                    )
                  else ...[
                    const Icon(
                      Icons.add_circle_rounded,
                      color: Color(0xFF1A0A00),
                      size: AppDimensions.iconLg,
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOLICITAR INCREMENTO',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: const Color(0xFF1A0A00),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '+\$100.000 al saldo base',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF3D2000),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Variant used for the "Iniciar Turno" first-launch action.
class IniciarTurnoButton extends StatelessWidget {
  const IniciarTurnoButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.tapTargetLg,
      child: FilledButton.icon(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.heavyImpact();
                onPressed();
              },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.statusGreen,
          foregroundColor: AppColors.onStatusGreen,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
        icon: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.play_arrow_rounded, size: AppDimensions.iconLg),
        label: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INICIAR TURNO',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.onStatusGreen,
              ),
            ),
            Text(
              'Base inicial: \$300.000',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onStatusGreen.withOpacity(0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
