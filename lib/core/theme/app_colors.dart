import 'package:flutter/material.dart';

/// Paleta "Violeta Nocturna" — fuente única de color para toda la app.
///
/// Primario : Violeta  #7C3AED — CTAs, selección, indicadores activos.
/// Secundario: Esmeralda #10B981 — éxito, dinero, confirmación.
/// Oscuro    : familia Zinc (casi negro cálido) + acentos violeta.
/// Claro     : blancos limpios + violeta + esmeralda.
abstract final class AppColors {
  // ── Brand / Primary ───────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF7C3AED); // violet-600
  static const Color primaryLight = Color(0xFFA78BFA); // violet-400
  static const Color primaryDark  = Color(0xFF5B21B6); // violet-800

  // ── Secondary / Success ───────────────────────────────────────────────────
  static const Color secondary      = Color(0xFF10B981); // emerald-500
  static const Color secondaryLight = Color(0xFF34D399); // emerald-400
  static const Color secondaryDark  = Color(0xFF059669); // emerald-600

  // ── Brand aliases (backwards compat) ─────────────────────────────────────
  static const Color brand      = primary;
  static const Color brandDark  = primaryDark;
  static const Color brandLight = primaryLight;

  // ── Chévere name aliases ──────────────────────────────────────────────────
  // Los nombres anteriores ahora apuntan a los nuevos colores.
  // Todo el código existente que use estos nombres hereda la nueva paleta
  // sin necesidad de modificar cada archivo.
  static const Color chevereTeal      = primary;
  static const Color chevereTealDark  = primaryDark;
  static const Color chevereTealLight = primaryLight;
  static const Color chevereOcre      = secondary;
  static const Color chevereBeige     = lightSurfaceVariant;
  static const Color cheverePizarra   = lightOnSurface;
  static const Color chevereBlanco    = lightBackground;

  // ── Status — Error / Pendiente ────────────────────────────────────────────
  static const Color statusRed    = Color(0xFFEF4444); // red-500
  static const Color statusRedDim = Color(0xFF991B1B); // red-800
  static const Color onStatusRed  = Color(0xFFFFFFFF);

  // ── Status — Éxito / Cobrado ──────────────────────────────────────────────
  static const Color statusGreen    = Color(0xFF34D399); // emerald-400
  static const Color statusGreenDim = Color(0xFF065F46); // emerald-900
  static const Color onStatusGreen  = Color(0xFF022C22);

  // ── Status — Advertencia / En progreso ───────────────────────────────────
  static const Color statusOrange   = Color(0xFFF97316); // orange-500
  static const Color onStatusOrange = Color(0xFFFFFFFF);

  // ── Status — Transferencia / Info ─────────────────────────────────────────
  static const Color statusBlue   = Color(0xFF38BDF8); // sky-400
  static const Color onStatusBlue = Color(0xFF082F49);

  // ── Status — Licor / Especial ─────────────────────────────────────────────
  static const Color statusPurple   = Color(0xFFC084FC); // purple-400
  static const Color onStatusPurple = Color(0xFF3B0764);

  // ── Dark Theme Surfaces (familia Zinc) ───────────────────────────────────
  static const Color darkBackground       = Color(0xFF09090B); // zinc-950
  static const Color darkSurface          = Color(0xFF18181B); // zinc-900
  static const Color darkSurfaceVariant   = Color(0xFF27272A); // zinc-800
  static const Color darkOutline          = Color(0xFF3F3F46); // zinc-700
  static const Color darkOutlineVariant   = Color(0xFF27272A); // zinc-800

  // ── Dark Theme Text ───────────────────────────────────────────────────────
  static const Color darkOnBackground     = Color(0xFFFAFAFA); // zinc-50
  static const Color darkOnSurface        = Color(0xFFFAFAFA); // zinc-50
  static const Color darkOnSurfaceVariant = Color(0xFFA1A1AA); // zinc-400
  static const Color darkDisabled         = Color(0xFF52525B); // zinc-600

  // ── Light Theme Surfaces ──────────────────────────────────────────────────
  static const Color lightBackground     = Color(0xFFF9FAFB); // gray-50
  static const Color lightSurface        = Color(0xFFFFFFFF); // white
  static const Color lightSurfaceVariant = Color(0xFFF3F4F6); // gray-100
  static const Color lightOutline        = Color(0xFFE5E7EB); // gray-200
  static const Color lightOutlineVariant = Color(0xFFF3F4F6); // gray-100

  // ── Light Theme Text ──────────────────────────────────────────────────────
  static const Color lightOnBackground     = Color(0xFF111827); // gray-900
  static const Color lightOnSurface        = Color(0xFF111827); // gray-900
  static const Color lightOnSurfaceVariant = Color(0xFF6B7280); // gray-500
  static const Color lightDisabled         = Color(0xFFD1D5DB); // gray-300

  // ── Scrim / Overlay ───────────────────────────────────────────────────────
  static const Color scrim      = Color(0xCC000000);
  static const Color scrimLight = Color(0x66000000);

  // ── Gradientes ────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Header modo oscuro: violeta profundo → zinc-950.
  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [Color(0xFF2D1B69), Color(0xFF09090B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  );

  /// Header modo claro: gradiente violeta.
  static const LinearGradient lightHeaderGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
