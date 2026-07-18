import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography system built for outdoor legibility.
///
/// Font: Nunito — geometric, rounded, excellent heavy-weight variants.
/// All weights skew bold: minimum w600 for body, w900 for display figures.
/// Letter-spacing is slightly relaxed on small sizes to avoid crowding.
abstract final class AppTextStyles {
  // ── Base font families ─────────────────────────────────────────────

  static TextStyle _nunito({
    required double size,
    required FontWeight weight,
    double letterSpacing = 0.0,
    double height = 1.25,
  }) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
      );

  // ── Display — large financial figures ─────────────────────────────

  /// Hero amounts: $300,000 COP on the base screen. 40 sp, w900.
  static TextStyle get displayLarge => _nunito(
        size: 40,
        weight: FontWeight.w900,
        letterSpacing: -0.5,
        height: 1.1,
      );

  /// Section totals. 32 sp, w900.
  static TextStyle get displayMedium => _nunito(
        size: 32,
        weight: FontWeight.w900,
        letterSpacing: -0.25,
        height: 1.15,
      );

  /// Invoice subtotals. 28 sp, w800.
  static TextStyle get displaySmall => _nunito(
        size: 28,
        weight: FontWeight.w800,
        height: 1.2,
      );

  // ── Headlines — screen titles ──────────────────────────────────────

  /// AppBar / screen titles. 24 sp, w800.
  static TextStyle get headlineLarge => _nunito(
        size: 24,
        weight: FontWeight.w800,
        height: 1.2,
      );

  /// Section headers. 20 sp, w800.
  static TextStyle get headlineMedium => _nunito(
        size: 20,
        weight: FontWeight.w800,
        height: 1.2,
      );

  /// Card headers. 18 sp, w700.
  static TextStyle get headlineSmall => _nunito(
        size: 18,
        weight: FontWeight.w700,
        height: 1.25,
      );

  // ── Titles — list items, tab labels ───────────────────────────────

  /// Table names, product names. 17 sp, w700.
  static TextStyle get titleLarge => _nunito(
        size: 17,
        weight: FontWeight.w700,
        height: 1.3,
      );

  /// Secondary list headings. 15 sp, w700.
  static TextStyle get titleMedium => _nunito(
        size: 15,
        weight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.3,
      );

  /// Chip labels, badge text. 13 sp, w700.
  static TextStyle get titleSmall => _nunito(
        size: 13,
        weight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.3,
      );

  // ── Body — readable content ────────────────────────────────────────

  /// Primary body copy. 16 sp, w600.
  static TextStyle get bodyLarge => _nunito(
        size: 16,
        weight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      );

  /// Secondary body. 14 sp, w600.
  static TextStyle get bodyMedium => _nunito(
        size: 14,
        weight: FontWeight.w600,
        letterSpacing: 0.25,
        height: 1.5,
      );

  /// Supporting body text. 13 sp, w600.
  static TextStyle get bodySmall => _nunito(
        size: 13,
        weight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.5,
      );

  // ── Labels — buttons, form fields ─────────────────────────────────

  /// Primary button labels. 16 sp, w800, wide tracking.
  static TextStyle get labelLarge => _nunito(
        size: 16,
        weight: FontWeight.w800,
        letterSpacing: 1.0,
        height: 1.2,
      );

  /// Secondary button / tab labels. 13 sp, w700.
  static TextStyle get labelMedium => _nunito(
        size: 13,
        weight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.2,
      );

  /// Helper / caption text. 12 sp, w600.
  static TextStyle get labelSmall => _nunito(
        size: 12,
        weight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.2,
      );

  // ── Status badge text ──────────────────────────────────────────────

  /// Uppercase status pills (PENDIENTE / PAGADO). 11 sp, w900.
  static TextStyle get statusBadge => _nunito(
        size: 11,
        weight: FontWeight.w900,
        letterSpacing: 1.5,
        height: 1.0,
      );

  // ── Monospace / Tiquete — facturas, cifras, códigos ────────────────
  // Space Mono da el carácter analógico de "papel térmico". Se carga vía
  // google_fonts igual que Nunito (mismo modelo de caché offline).

  static TextStyle _mono({
    required double size,
    required FontWeight weight,
    double letterSpacing = 0.0,
    double height = 1.35,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// Código de verificación / timestamps. 14 sp.
  static TextStyle get mono => _mono(
        size: 14,
        weight: FontWeight.w700,
        letterSpacing: 1.0,
        height: 1.4,
      );

  /// Encabezado del tiquete (nombre del bar). 18 sp, bold.
  static TextStyle get receiptTitle => _mono(
        size: 18,
        weight: FontWeight.w700,
        letterSpacing: 2.0,
        height: 1.3,
      );

  /// Línea de ítem en el tiquete. 14 sp.
  static TextStyle get receiptBody => _mono(
        size: 14,
        weight: FontWeight.w400,
        height: 1.5,
      );

  /// Línea de ítem enfatizada (cantidad, precio). 14 sp, bold.
  static TextStyle get receiptBodyBold => _mono(
        size: 14,
        weight: FontWeight.w700,
        height: 1.5,
      );

  /// Texto pequeño del tiquete (hora, c/u, subtítulos). 11.5 sp.
  static TextStyle get receiptSmall => _mono(
        size: 11.5,
        weight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.4,
      );

  /// Totales del tiquete (TOTAL / SALDO). 16 sp, bold.
  static TextStyle get receiptTotal => _mono(
        size: 16,
        weight: FontWeight.w700,
        letterSpacing: 1.0,
        height: 1.4,
      );

  // ── Convenience: apply color to any style ─────────────────────────

  static TextStyle dark(TextStyle base) =>
      base.copyWith(color: AppColors.darkOnBackground);

  static TextStyle light(TextStyle base) =>
      base.copyWith(color: AppColors.lightOnBackground);

  static TextStyle brand(TextStyle base) =>
      base.copyWith(color: AppColors.brand);

  static TextStyle red(TextStyle base) =>
      base.copyWith(color: AppColors.statusRed);

  static TextStyle green(TextStyle base) =>
      base.copyWith(color: AppColors.statusGreen);

  // ── TextTheme builders ─────────────────────────────────────────────

  static TextTheme buildTextTheme(Color primaryColor) => TextTheme(
        displayLarge: displayLarge.copyWith(color: primaryColor),
        displayMedium: displayMedium.copyWith(color: primaryColor),
        displaySmall: displaySmall.copyWith(color: primaryColor),
        headlineLarge: headlineLarge.copyWith(color: primaryColor),
        headlineMedium: headlineMedium.copyWith(color: primaryColor),
        headlineSmall: headlineSmall.copyWith(color: primaryColor),
        titleLarge: titleLarge.copyWith(color: primaryColor),
        titleMedium: titleMedium.copyWith(color: primaryColor),
        titleSmall: titleSmall.copyWith(color: primaryColor),
        bodyLarge: bodyLarge.copyWith(color: primaryColor),
        bodyMedium: bodyMedium.copyWith(color: primaryColor),
        bodySmall: bodySmall.copyWith(color: primaryColor),
        labelLarge: labelLarge.copyWith(color: primaryColor),
        labelMedium: labelMedium.copyWith(color: primaryColor),
        labelSmall: labelSmall.copyWith(color: primaryColor),
      );
}
