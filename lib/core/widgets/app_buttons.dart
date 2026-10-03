import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Botón principal de acción en "The Base" — Paper Receipt Aesthetic.
///
/// Especificaciones de diseño unificadas:
///   • Altura estándar: 52px fija.
///   • Border radius idéntico: 14px.
///   • Padding interno balanceado: 20px horizontal, 14px vertical.
///   • Respuesta háptica integrada [HapticFeedback.mediumImpact].
///   • Estados visuales claros al pulsar (splash / ripple).
///   • Soporte para [icon], estado de carga [isLoading] y deshabilitado claro.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.color = AppColors.primary,
    this.textColor = Colors.white,
    this.height = AppDimensions.buttonHeightMd, // 52px
    this.width = double.infinity,
    this.borderRadius = AppDimensions.buttonRadius, // 14px
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isEnabled;
  final Color color;
  final Color textColor;
  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && !isLoading && onPressed != null;

    return AnimatedOpacity(
      opacity: canTap ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 180),
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
          elevation: 0,
          child: InkWell(
            onTap: canTap
                ? () {
                    HapticFeedback.mediumImpact();
                    onPressed!();
                  }
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  else ...[
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
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

/// Botón secundario contorneado u opcionalmente con fondo suave de papel.
///
/// Especificaciones de diseño unificadas:
///   • Altura estándar: 52px (o 40px en modo compacto).
///   • Border radius idéntico: 14px.
///   • Borde de papel sutil [AppColors.paperBorder] o del color de acento.
///   • Respuesta háptica [HapticFeedback.lightImpact].
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.accentColor = AppColors.primary,
    this.backgroundColor = Colors.transparent,
    this.borderColor,
    this.height = AppDimensions.buttonHeightMd, // 52px
    this.width = double.infinity,
    this.borderRadius = AppDimensions.buttonRadius, // 14px
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isEnabled;
  final Color accentColor;
  final Color backgroundColor;
  final Color? borderColor;
  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && !isLoading && onPressed != null;
    final resolvedBorderColor = borderColor ?? AppColors.paperBorder;

    return AnimatedOpacity(
      opacity: canTap ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 180),
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: canTap
                  ? resolvedBorderColor
                  : resolvedBorderColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: canTap
                ? () {
                    HapticFeedback.lightImpact();
                    onPressed!();
                  }
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: accentColor.withValues(alpha: 0.12),
            highlightColor: accentColor.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    )
                  else ...[
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
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

/// Botón compacto de acción secundaria o chip interactivo (40px de altura).
///
/// Especificaciones unificadas:
///   • Altura: 40px fija.
///   • Border radius: 12px a 14px.
///   • Padding horizontal: 14px.
///   • Respuesta háptica [HapticFeedback.selectionClick].
class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isSelected = false,
    this.selectedColor = AppColors.primary,
    this.unselectedColor = AppColors.paperSurfaceAlt,
    this.borderColor,
    this.height = AppDimensions.buttonHeightSm, // 40px
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color? borderColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ??
        (isSelected
            ? selectedColor
            : AppColors.paperBorder);

    return SizedBox(
      height: height,
      child: Material(
        color: isSelected ? selectedColor : unselectedColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: effectiveBorderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: onPressed != null
              ? () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
