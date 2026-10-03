import 'package:flutter/material.dart';

/// Paleta global unificada para "The Base" — Paper Receipt Aesthetic (Ticket de Papel Beige).
///
/// Concepto oficial e inmutable:
/// - Fondo Principal de la App (Scaffold): Beige cálido / Crema de papel (`#FBF8F2`).
/// - Superficies y Tarjetas (Cards / Tickets): Blanco papel suave (`#FFFDF9` / `#FFFFFF`)
///   con bordes sutiles de papel (`#EADBCE`), esquinas redondeadas uniformes (16px)
///   o remates sutiles estilo comanda.
/// - Textos y Números (Tinta de Impresión de alto contraste para exteriores):
///   * Tinta principal: Carbón profundo / Espresso oscuro (`#1E1C1A`).
///   * Textos secundarios y notas: Ceniza tostado (`#7A7269`).
/// - Colores de Acento y Funcionales:
///   * Ámbar Cálido / Mostaza: Pestañas activas, incrementos y alertas primarias (`#D97706`).
///   * Verde Esmeralda / Salvia: Botones de confirmación, cobrado, estados positivos (`#10B981` / `#059669`).
///   * Rojo Coral / Terracota: Tiempos transcurridos prolongados, deudas y cancelaciones (`#EF4444` / `#DC2626`).
abstract final class AppColors {
  // ── Brand / Primary — Ámbar Cálido / Mostaza ─────────────────────────────
  static const Color primary      = Color(0xFFD97706); // Ámbar cálido / Mostaza
  static const Color primaryLight = Color(0xFFF59E0B); // Ámbar luminoso
  static const Color primaryDark  = Color(0xFFB45309); // Ámbar tostado profundo
  static const Color onPrimary    = Color(0xFFFFFFFF); // Tinta clara sobre ámbar

  // ── Secondary / Success — Verde Esmeralda / Salvia ───────────────────────
  static const Color secondary      = Color(0xFF10B981); // Verde esmeralda
  static const Color secondaryLight = Color(0xFF34D399); // Menta suave
  static const Color secondaryDark  = Color(0xFF059669); // Salvia profundo
  static const Color onSecondary    = Color(0xFFFFFFFF);

  // ── Brand aliases (backwards compat) ─────────────────────────────────────
  static const Color brand      = primary;
  static const Color brandDark  = primaryDark;
  static const Color brandLight = primaryLight;

  // ── Papel de tiquete / Recibo (Paper Receipt Aesthetic) ───────────────────
  static const Color paperBackground = Color(0xFFFBF8F2); // Beige cálido / Crema de papel
  static const Color paperSurface    = Color(0xFFFFFDF9); // Blanco papel suave
  static const Color paperSurfaceAlt = Color(0xFFF7F4EB); // Papel crema sutil
  static const Color paperCard       = Color(0xFFFFFFFF); // Tarjeta papel pura
  static const Color paperBorder     = Color(0xFFEADBCE); // Borde sutil de papel
  static const Color paperLine       = Color(0xFFEADBCE); // Líneas punteadas / perforación
  static const Color paperShadow     = Color(0x0F2D2A26); // Sombra suave de papel

  // ── Tinta de Impresión (Contraste alto para exteriores bajo el sol) ──────
  static const Color ink          = Color(0xFF1E1C1A); // Carbón profundo / Espresso oscuro
  static const Color inkSecondary = Color(0xFF7A7269); // Ceniza tostado (notas / subtítulos)
  static const Color inkDisabled  = Color(0xFFA8A199); // Tinta atenuada
  static const Color inkLight     = Color(0xFFFBF8F2); // Tinta clara para botones sólidos

  // ── Aliases de papel y compatibilidad ─────────────────────────────────────
  static const Color paper        = paperSurface;
  static const Color paperDim     = paperSurfaceAlt;
  static const Color paperInk     = ink;
  static const Color paperInkSoft = inkSecondary;

  // ── Aliases heredados (Chevere legacy) ────────────────────────────────────
  static const Color chevereTeal      = primary;
  static const Color chevereTealDark  = primaryDark;
  static const Color chevereTealLight = primaryLight;
  static const Color chevereOcre      = secondary;
  static const Color chevereBeige     = paperBackground;
  static const Color cheverePizarra   = ink;
  static const Color chevereBlanco    = paperSurface;

  // ── Status — Error / Alerta / Cancelación (Rojo Coral / Terracota) ────────
  static const Color statusRed    = Color(0xFFEF4444); // Rojo coral
  static const Color statusRedDim = Color(0xFFFEE2E2); // Fondo tenue error
  static const Color onStatusRed  = Color(0xFFFFFFFF);

  // ── Status — Éxito / Cobrado (Verde Esmeralda / Salvia) ───────────────────
  static const Color statusGreen    = Color(0xFF10B981); // Verde esmeralda
  static const Color statusGreenDim = Color(0xFFD1FAE5); // Fondo tenue éxito
  static const Color onStatusGreen  = Color(0xFFFFFFFF);

  // ── Status — Advertencia / En progreso (Ámbar Cálido) ─────────────────────
  static const Color statusOrange    = Color(0xFFD97706); // Ámbar cálido
  static const Color statusOrangeDim = Color(0xFFFEF3C7);
  static const Color onStatusOrange  = Color(0xFFFFFFFF);

  // ── Status — Transferencia / Info (Azul Eléctrico Suave) ─────────────────
  static const Color statusBlue    = Color(0xFF2563EB); // Azul transferencia
  static const Color statusBlueDim = Color(0xFFDBEAFE);
  static const Color onStatusBlue  = Color(0xFFFFFFFF);

  // ── Status — Licor / Especial (Púrpura Borbón / Licor) ───────────────────
  static const Color statusPurple    = Color(0xFF7C3AED); // Licor / Botellas
  static const Color statusPurpleDim = Color(0xFFEDE9FE);
  static const Color onStatusPurple  = Color(0xFFFFFFFF);

  // ── Superficies del Tema Claro Beige (Canónico e Inmutable) ───────────────
  static const Color lightBackground       = paperBackground;
  static const Color lightSurface          = paperSurface;
  static const Color lightSurfaceVariant   = paperSurfaceAlt;
  static const Color lightCard             = paperCard;
  static const Color lightOutline          = paperBorder;
  static const Color lightOutlineVariant   = Color(0xFFF0E5D8);

  // ── Textos del Tema Claro Beige ───────────────────────────────────────────
  static const Color lightOnBackground     = ink;
  static const Color lightOnSurface        = ink;
  static const Color lightOnSurfaceVariant = inkSecondary;
  static const Color lightDisabled         = inkDisabled;

  // ── Modos Oscuros Verdaderos (Carbon Contrast) ─────────────────────────────
  // Implementación de Dark Mode de alto contraste y legibilidad nocturna
  static const Color darkBackground       = Color(0xFF121212); // Negro Carbón Profundo
  static const Color darkSurface          = Color(0xFF1E1F21); // Gris Grafito pulido
  static const Color darkSurfaceVariant   = Color(0xFF252628); // Grafito más claro
  static const Color darkCard             = Color(0xFF1E1F21); // Tarjeta Oscura
  static const Color darkOutline          = Color(0x1FFFFFFF); // Border.all(color: Colors.white12) => aprox 12%-1E%
  static const Color darkOutlineVariant   = Color(0x33FFFFFF); // 20% white

  static const Color darkOnBackground     = Color(0xFFF5F5F7); // Blanco tiza alto impacto
  static const Color darkOnSurface        = Color(0xFFF5F5F7); 
  static const Color darkOnSurfaceVariant = Color(0xFFA0A0A5); // Gris humo cálido
  static const Color darkDisabled         = Color(0xFF6B6B6D);

  // ── Barra de navegación inferior ─────────────────────────────────────────
  static const Color navBarDark  = Color(0xFF1E1F21);
  static const Color navBarLight = paperSurface;

  // ── Scrim / Overlay ───────────────────────────────────────────────────────
  static const Color scrim      = Color(0x99000000);
  static const Color scrimLight = Color(0x331E1C1A);

  // ── Gradientes Estilo Papel Beige ─────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Header de papel cálido con relieve sutil: crema superior → beige sutil.
  static const LinearGradient paperHeaderGradient = LinearGradient(
    colors: [Color(0xFFFFFDF9), Color(0xFFF7F4EB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Header oscuro sutil
  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [Color(0xFF1E1F21), Color(0xFF121212)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightHeaderGradient = paperHeaderGradient;
}
