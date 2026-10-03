import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Primary action button for requesting a base increase (monto configurable en Ajustes).
///
/// Design requirements:
///   • 52dp standardized height with 14px border radius.
///   • Warm Amber color (#D97706) for high contrast and quick recognition.
///   • Haptic feedback on tap.
///   • [isLoading] replaces the label with a spinner during async work.
///   • [isEnabled] dims the button when the shift is not yet initialized.
class IncrementoButton extends StatelessWidget {
  const IncrementoButton({
    super.key,
    required this.onPressed,
    required this.amount,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final VoidCallback onPressed;
  final int amount;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightMd, // 52px
      child: AnimatedOpacity(
        opacity: canTap ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          child: InkWell(
            onTap: canTap
                ? () {
                    HapticFeedback.mediumImpact();
                    onPressed();
                  }
                : null,
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
            splashColor: Colors.white.withValues(alpha: 0.22),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else ...[
                    const Icon(
                      Icons.add_circle_rounded,
                      color: Colors.white,
                      size: AppDimensions.iconMd,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOLICITAR INCREMENTO',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '+${amount.toCop} al saldo base',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
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
    required this.amount,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final int amount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightMd, // 52px
      child: FilledButton.icon(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.heavyImpact();
                onPressed();
              },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.statusGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTextStyles.labelLarge,
          elevation: 0,
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.play_arrow_rounded, size: AppDimensions.iconMd),
        label: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INICIAR TURNO',
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Base inicial: ${amount.toCop}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
