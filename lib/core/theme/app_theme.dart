import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// Genera [ThemeData] para "The Base" — Identidad Visual Oficial: Paper Receipt Aesthetic.
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
abstract final class AppTheme {
  // ── Color Schemes ──────────────────────────────────────────────────────────

  static const ColorScheme _paperScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.statusOrangeDim,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.statusGreenDim,
    onSecondaryContainer: AppColors.secondaryDark,
    tertiary: AppColors.statusBlue,
    onTertiary: AppColors.onStatusBlue,
    tertiaryContainer: AppColors.statusBlueDim,
    onTertiaryContainer: Color(0xFF1E40AF),
    error: AppColors.statusRed,
    onError: AppColors.onStatusRed,
    errorContainer: AppColors.statusRedDim,
    onErrorContainer: Color(0xFF991B1B),
    surface: AppColors.paperSurface,
    onSurface: AppColors.ink,
    surfaceDim: AppColors.paperBackground,
    surfaceBright: AppColors.paperCard,
    surfaceContainerLowest: AppColors.paperBackground,
    surfaceContainerLow: AppColors.paperSurfaceAlt,
    surfaceContainer: AppColors.paperSurface,
    surfaceContainerHigh: AppColors.paperSurfaceAlt,
    surfaceContainerHighest: Color(0xFFEFE9DC),
    onSurfaceVariant: AppColors.inkSecondary,
    surfaceTint: Colors.transparent,
    outline: AppColors.paperBorder,
    outlineVariant: AppColors.lightOutlineVariant,
    shadow: AppColors.paperShadow,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.ink,
    onInverseSurface: AppColors.paperSurface,
    inversePrimary: AppColors.primaryLight,
  );

  // ── ThemeData públicos ──────────────────────────────────────────────────────

  static ThemeData get light => _build(_paperScheme);
  // El tema inmutable de la app es el papel beige; dark hereda la misma paleta cálida
  static ThemeData get dark  => _build(_paperScheme);

  // ── Builder ────────────────────────────────────────────────────────────────

  static ThemeData _build(ColorScheme scheme) {
    const Color onSurface  = AppColors.ink;
    const Color surface    = AppColors.paperSurface;
    const Color background = AppColors.paperBackground;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,

      // ── Tipografía (Tinta de Impresión de Alto Contraste) ───────────────────
      textTheme: AppTextStyles.buildTextTheme(onSurface),
      primaryTextTheme: AppTextStyles.buildTextTheme(scheme.primary),

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: AppDimensions.appBarElevation,
        scrolledUnderElevation: 0,
        toolbarHeight: AppDimensions.appBarHeight,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(
          color: onSurface,
          size: AppDimensions.iconMd,
        ),
        centerTitle: false,
      ),

      // ── ElevatedButton (52px estándar, 14px radius) ─────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),

      // ── OutlinedButton (52px estándar, 14px radius, borde sutil de papel) ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(
            color: AppColors.paperBorder,
            width: AppDimensions.buttonBorderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(
            AppDimensions.tapTargetMin,
            AppDimensions.tapTargetMin,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      // ── FilledButton (52px estándar, 14px radius) ───────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),

      // ── NavigationBar ───────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.16),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.labelSmall.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.inkSecondary,
            size: AppDimensions.iconMd,
          );
        }),
      ),

      // ── BottomSheet (Superficie papel beige, 20px borde superior) ───────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.modalRadius),
          ),
        ),
      ),

      // ── Menus ───────────────────────────────────────────────────────────────
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(2),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
      ),

      canvasColor: surface,

      // ── Card (Blanco papel suave, borde papel 1px, 16px radius) ────────────
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppDimensions.cardElevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          side: const BorderSide(
            color: AppColors.paperBorder,
            width: 1.0,
          ),
        ),
      ),

      // ── Input (Campos de entrada en papel limpio) ───────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: const BorderSide(
            color: AppColors.paperBorder,
            width: AppDimensions.inputBorderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: const BorderSide(
            color: AppColors.paperBorder,
            width: AppDimensions.inputBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: BorderSide(
            color: scheme.primary,
            width: AppDimensions.inputBorderWidth + 0.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: const BorderSide(
            color: AppColors.statusRed,
            width: AppDimensions.inputBorderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          borderSide: const BorderSide(
            color: AppColors.statusRed,
            width: AppDimensions.inputBorderWidth + 0.5,
          ),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inkSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inkDisabled,
        ),
        errorStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.statusRed,
        ),
        constraints: const BoxConstraints(minHeight: AppDimensions.inputHeight),
      ),

      // ── Chip (40px alto, papel crema, borde sutil) ──────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paperSurfaceAlt,
        selectedColor: AppColors.primary.withValues(alpha: 0.16),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(
          color: AppColors.paperBorder,
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space10,
          vertical: AppDimensions.space6,
        ),
      ),

      // ── BottomNavigationBar (legacy) ────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.inkSecondary,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Divider (Línea de papel sutil) ──────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.paperBorder,
        thickness: AppDimensions.dividerThickness,
        space: 0,
      ),

      // ── Dialog (20px bordes redondeados, superficie papel) ──────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.modalRadius),
          side: const BorderSide(color: AppColors.paperBorder, width: 1.0),
        ),
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: AppTextStyles.bodyLarge.copyWith(color: onSurface),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.paperSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── ListTile ─────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        minTileHeight: AppDimensions.tapTargetStd,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH,
          vertical: AppDimensions.space4,
        ),
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.inkSecondary,
        ),
        iconColor: scheme.primary,
      ),

      // ── Checkbox ─────────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
        side: const BorderSide(
          color: AppColors.paperBorder,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),

      // ── FAB ──────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        ),
        extendedTextStyle: AppTextStyles.labelLarge.copyWith(color: Colors.white),
      ),

      // ── Icons ─────────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: onSurface, size: AppDimensions.iconMd),
      primaryIconTheme:
          IconThemeData(color: scheme.primary, size: AppDimensions.iconMd),

      // ── TabBar ───────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.inkSecondary,
        labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
