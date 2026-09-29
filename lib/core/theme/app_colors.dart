import 'package:flutter/material.dart';

/// Paleta global unificada para "The Base" — Dark Premium & High-Contrast.
///
/// Concepto: Fondo carbón oscuro / negro mate (`#121212` / `#18191A`),
/// tarjetas de gris grafito pulido (`#242526` / `#2D2F31`), acentos funcionales
/// en ámbar cálido (`#FFB300`), verde esmeralda neón (`#00E676`) y coral (`#FF5252`).
abstract final class AppColors {
  // ── Brand / Primary — Ámbar Cálido / Dorado ───────────────────────────────
  static const Color primary      = Color(0xFFFFB300); // Ámbar cálido / Dorado
  static const Color primaryLight = Color(0xFFFFC107); // Ámbar claro
  static const Color primaryDark  = Color(0xFFF5A623); // Dorado profundo

  // ── Secondary / Success — Verde Esmeralda / Neón ─────────────────────────
  static const Color secondary      = Color(0xFF00E676); // Verde esmeralda neón
  static const Color secondaryLight = Color(0xFF69F0AE); // Menta luminoso
  static const Color secondaryDark  = Color(0xFF00C853); // Esmeralda sólido

  // ── Brand aliases (backwards compat) ─────────────────────────────────────
  static const Color brand      = primary;
  static const Color brandDark  = primaryDark;
  static const Color brandLight = primaryLight;

  // ── Aliases heredados ────────────────────────────────────────────────────
  static const Color chevereTeal      = primary;
  static const Color chevereTealDark  = primaryDark;
  static const Color chevereTealLight = primaryLight;
  static const Color chevereOcre      = secondary;
  static const Color chevereBeige     = darkSurfaceVariant;
  static const Color cheverePizarra   = darkOnSurface;
  static const Color chevereBlanco    = darkBackground;

  // ── Papel de tiquete / Recibo (Moderno Oscuro Grafito) ───────────────────
  static const Color paper        = Color(0xFF242526); // Gris grafito pulido
  static const Color paperDim     = Color(0xFF1E1F21); // Grafito alterno
  static const Color paperInk     = Color(0xFFF5F6F8); // Tipografía clara nítida
  static const Color paperInkSoft = Color(0xFFA0A3A8); // Tinta desvaída / subtítulos
  static const Color paperLine    = Color(0x26FFFFFF); // Líneas sutiles

  // ── Status — Error / Alerta / Cancelación (Coral / Carmesí) ──────────────
  static const Color statusRed    = Color(0xFFFF5252); // Coral / Carmesí vibrante
  static const Color statusRedDim = Color(0xFFB71C1C);
  static const Color onStatusRed  = Color(0xFFFFFFFF);

  // ── Status — Éxito / Cobrado (Verde Esmeralda Neón) ──────────────────────
  static const Color statusGreen    = Color(0xFF00E676);
  static const Color statusGreenDim = Color(0xFF004D25);
  static const Color onStatusGreen  = Color(0xFF00240D);

  // ── Status — Advertencia / En progreso (Ámbar cálido) ────────────────────
  static const Color statusOrange   = Color(0xFFFFA000);
  static const Color onStatusOrange = Color(0xFF2A1600);

  // ── Status — Transferencia / Info (Azul Eléctrico) ───────────────────────
  static const Color statusBlue   = Color(0xFF448AFF);
  static const Color onStatusBlue = Color(0xFF06183A);

  // ── Status — Licor / Especial (Púrpura Neón / Borbón) ────────────────────
  static const Color statusPurple   = Color(0xFFAB47BC); // Licor / Botellas
  static const Color onStatusPurple = Color(0xFFFFFFFF);

  // ── Dark Theme Surfaces (Carbón oscuro / Negro mate + Grafito pulido) ─────
  static const Color darkBackground       = Color(0xFF121212); // Negro mate carbón
  static const Color darkSurface          = Color(0xFF18191A); // Superficie principal
  static const Color darkSurfaceVariant   = Color(0xFF242526); // Tarjetas grafito pulido
  static const Color darkCard             = Color(0xFF2D2F31); // Tarjetas elevadas
  static const Color darkOutline          = Color(0x1FFFFFFF); // Borde sutil blanco (0.08)
  static const Color darkOutlineVariant   = Color(0x14FFFFFF); // Borde ultra sutil (0.05)

  // ── Dark Theme Text ───────────────────────────────────────────────────────
  static const Color darkOnBackground     = Color(0xFFF5F6F8); // Blanco nítido
  static const Color darkOnSurface        = Color(0xFFF5F6F8);
  static const Color darkOnSurfaceVariant = Color(0xFFA0A3A8); // Gris medio legible
  static const Color darkDisabled         = Color(0xFF65676B);

  // ── Light Theme Surfaces (Fallback cálido de alta fidelidad) ─────────────
  static const Color lightBackground     = Color(0xFFF0F2F5);
  static const Color lightSurface        = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE4E6EB);
  static const Color lightOutline        = Color(0xFFCED0D4);
  static const Color lightOutlineVariant = Color(0xFFE4E6EB);

  // ── Light Theme Text ──────────────────────────────────────────────────────
  static const Color lightOnBackground     = Color(0xFF1C1E21);
  static const Color lightOnSurface        = Color(0xFF1C1E21);
  static const Color lightOnSurfaceVariant = Color(0xFF65676B);
  static const Color lightDisabled         = Color(0xFFB0B3B8);

  // ── Nav bar background (bottom navigation) ───────────────────────────────
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

  /// Header modo oscuro: carbón ámbar sutil → negro mate.
  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [Color(0xFF261D0F), Color(0xFF121212)],
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
