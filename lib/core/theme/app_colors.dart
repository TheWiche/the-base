import 'package:flutter/material.dart';

/// Paleta "Tiquete" — fuente única de color para toda la app.
///
/// Concepto: shell oscuro casi-negro + facturas de papel crema + acento ámbar
/// (mostaza) + verde para dinero/confirmación. Tipografía monoespaciada.
/// Reemplaza la antigua paleta violeta ("hecha por IA"). Los nombres de
/// constantes se conservan para que el resto del código herede el nuevo look
/// sin tocar cada archivo.
///
/// Primario : Ámbar   #E0A63C — CTAs, selección, indicadores activos.
/// Dinero   : Verde   #46B67F — éxito, cobrar, confirmación.
/// Papel    : Crema   #F2ECDC — facturas/tiquetes (igual en claro y oscuro).
abstract final class AppColors {
  // ── Brand / Primary — Ámbar tiquete ───────────────────────────────────────
  static const Color primary      = Color(0xFFE0A63C); // amber/mostaza
  static const Color primaryLight = Color(0xFFF0C674); // amber claro
  static const Color primaryDark  = Color(0xFFB07E22); // amber quemado

  // ── Secondary / Success — Verde dinero ────────────────────────────────────
  static const Color secondary      = Color(0xFF46B67F);
  static const Color secondaryLight = Color(0xFF6ECB9C);
  static const Color secondaryDark  = Color(0xFF2F8C5F);

  // ── Brand aliases (backwards compat) ─────────────────────────────────────
  static const Color brand      = primary;
  static const Color brandDark  = primaryDark;
  static const Color brandLight = primaryLight;

  // ── Aliases heredados (apuntan a la paleta nueva) ─────────────────────────
  // Todo el código que use estos nombres hereda la nueva paleta sin editar.
  static const Color chevereTeal      = primary;
  static const Color chevereTealDark  = primaryDark;
  static const Color chevereTealLight = primaryLight;
  static const Color chevereOcre      = secondary;
  static const Color chevereBeige     = lightSurfaceVariant;
  static const Color cheverePizarra   = lightOnSurface;
  static const Color chevereBlanco    = lightBackground;

  // ── Papel de tiquete (crema, igual en ambos temas) ────────────────────────
  static const Color paper        = Color(0xFFF2ECDC); // papel crema
  static const Color paperDim     = Color(0xFFE7DFC9); // crema alterno (cebra)
  static const Color paperInk     = Color(0xFF1A1A22); // tinta casi-negra
  static const Color paperInkSoft = Color(0xFF6B6450); // tinta desvaída
  static const Color paperLine    = Color(0xFFB9AE90); // líneas punteadas

  // ── Status — Error / Pendiente (rojo sello) ───────────────────────────────
  static const Color statusRed    = Color(0xFFD6483B); // rojo sello
  static const Color statusRedDim = Color(0xFF7F241C);
  static const Color onStatusRed  = Color(0xFFFFFFFF);

  // ── Status — Éxito / Cobrado (verde) ──────────────────────────────────────
  static const Color statusGreen    = Color(0xFF46B67F);
  static const Color statusGreenDim = Color(0xFF0F5537);
  static const Color onStatusGreen  = Color(0xFF03251A);

  // ── Status — Advertencia / En progreso (ámbar cálido) ─────────────────────
  static const Color statusOrange   = Color(0xFFE0872C);
  static const Color onStatusOrange = Color(0xFF2A1600);

  // ── Status — Transferencia / Info ─────────────────────────────────────────
  static const Color statusBlue   = Color(0xFF5B8DEF);
  static const Color onStatusBlue = Color(0xFF06183A);

  // ── Status — Licor / Especial (whisky ámbar-marrón) ───────────────────────
  static const Color statusPurple   = Color(0xFFC0873E); // licor
  static const Color onStatusPurple = Color(0xFF2A1A06);

  // ── Dark Theme Surfaces (shell casi-negro cálido) ─────────────────────────
  static const Color darkBackground       = Color(0xFF0B0B10);
  static const Color darkSurface          = Color(0xFF14141C);
  static const Color darkSurfaceVariant   = Color(0xFF1E1E28);
  static const Color darkOutline          = Color(0xFF34343F);
  static const Color darkOutlineVariant   = Color(0xFF26262F);

  // ── Dark Theme Text (blanco cálido) ───────────────────────────────────────
  static const Color darkOnBackground     = Color(0xFFF5F1E6);
  static const Color darkOnSurface        = Color(0xFFF5F1E6);
  static const Color darkOnSurfaceVariant = Color(0xFFA7A296);
  static const Color darkDisabled         = Color(0xFF55555F);

  // ── Light Theme Surfaces (cálido, no blanco frío) ─────────────────────────
  static const Color lightBackground     = Color(0xFFFAF7EF);
  static const Color lightSurface        = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1EBDD);
  static const Color lightOutline        = Color(0xFFE2D9C6);
  static const Color lightOutlineVariant = Color(0xFFEFE9DB);

  // ── Light Theme Text ──────────────────────────────────────────────────────
  static const Color lightOnBackground     = Color(0xFF1F1B12);
  static const Color lightOnSurface        = Color(0xFF1F1B12);
  static const Color lightOnSurfaceVariant = Color(0xFF6B6552);
  static const Color lightDisabled         = Color(0xFFC9C0AD);

  // ── Nav bar background (bottom navigation) ───────────────────────────────
  // Se funden con el shell para camuflar el velo de gestos de MIUI: el nav bar
  // custom en app_router usa darkBackground/lightBackground directamente; estos
  // alias apuntan a lo mismo por si algún tema los referencia.
  static const Color navBarDark  = darkBackground;
  static const Color navBarLight = lightBackground;

  // ── Scrim / Overlay ───────────────────────────────────────────────────────
  static const Color scrim      = Color(0xCC000000);
  static const Color scrimLight = Color(0x66000000);

  // ── Gradientes ────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Header modo oscuro: ámbar quemado → shell casi-negro.
  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [Color(0xFF3A2A0F), Color(0xFF0B0B10)],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  );

  /// Header modo claro: gradiente ámbar.
  static const LinearGradient lightHeaderGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
