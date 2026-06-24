import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// Genera [ThemeData] para modo oscuro y claro — Paleta "Violeta Nocturna".
///
/// Oscuro → Zinc casi-negro + violeta primario + esmeralda secundaria.
/// Claro  → Blanco limpio + violeta primario + esmeralda secundaria.
abstract final class AppTheme {
  // ── Color Schemes ──────────────────────────────────────────────────────────

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF2E1065),    // violet-950
    onPrimaryContainer: Color(0xFFEDE9FE), // violet-100
    secondary: AppColors.secondary,
    onSecondary: Color(0xFF022C22),
    secondaryContainer: Color(0xFF064E3B),
    onSecondaryContainer: Color(0xFFD1FAE5),
    tertiary: AppColors.statusBlue,
    onTertiary: Color(0xFF082F49),
    tertiaryContainer: Color(0xFF0C4A6E),
    onTertiaryContainer: Color(0xFFE0F2FE),
    error: AppColors.statusRed,
    onError: AppColors.onStatusRed,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    surfaceDim: AppColors.darkBackground,
    surfaceBright: AppColors.darkSurfaceVariant,
    surfaceContainerLowest: AppColors.darkBackground,
    surfaceContainerLow: AppColors.darkSurface,
    surfaceContainer: AppColors.darkSurface,
    surfaceContainerHigh: AppColors.darkSurfaceVariant,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    surfaceTint: Colors.transparent,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
    shadow: Colors.black,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.lightSurface,
    onInverseSurface: AppColors.lightOnSurface,
    inversePrimary: AppColors.primaryLight,
  );

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEDE9FE),    // violet-100
    onPrimaryContainer: Color(0xFF2E1065), // violet-950
    secondary: AppColors.secondaryDark,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD1FAE5), // emerald-100
    onSecondaryContainer: Color(0xFF022C22),
    tertiary: Color(0xFF0284C7),           // sky-600
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE0F2FE),
    onTertiaryContainer: Color(0xFF082F49),
    error: Color(0xFFDC2626),             // red-600
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    surfaceDim: AppColors.lightSurfaceVariant,
    surfaceBright: AppColors.lightBackground,
    surfaceContainerLowest: AppColors.lightBackground,
    surfaceContainerLow: AppColors.lightSurface,
    surfaceContainer: AppColors.lightSurface,
    surfaceContainerHigh: AppColors.lightSurfaceVariant,
    surfaceContainerHighest: AppColors.lightSurfaceVariant,
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,
    surfaceTint: Colors.transparent,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutlineVariant,
    shadow: Color(0x33000000),
    scrim: AppColors.scrimLight,
    inverseSurface: AppColors.darkSurface,
    onInverseSurface: AppColors.darkOnSurface,
    inversePrimary: AppColors.primaryDark,
  );

  // ── ThemeData públicos ──────────────────────────────────────────────────────

  static ThemeData get dark  => _build(_darkScheme);
  static ThemeData get light => _build(_lightScheme);

  // ── Builder ────────────────────────────────────────────────────────────────

  static ThemeData _build(ColorScheme scheme) {
    final bool isDark   = scheme.brightness == Brightness.dark;
    final Color onSurface  = isDark ? AppColors.darkOnSurface  : AppColors.lightOnSurface;
    final Color surface    = isDark ? AppColors.darkSurface    : AppColors.lightSurface;
    final Color background = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,

      // ── Tipografía ──────────────────────────────────────────────────────────
      textTheme: AppTextStyles.buildTextTheme(onSurface),
      primaryTextTheme: AppTextStyles.buildTextTheme(scheme.primary),

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        surfaceTintColor: Colors.transparent,
        elevation: AppDimensions.appBarElevation,
        scrolledUnderElevation: 0,
        toolbarHeight: AppDimensions.appBarHeight,
        titleTextStyle: AppTextStyles.headlineLarge.copyWith(
          color: isDark ? AppColors.darkOnBackground : AppColors.lightOnSurface,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
          size: AppDimensions.iconMd,
        ),
        centerTitle: false,
      ),

      // ── ElevatedButton ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextStyles.labelLarge,
          elevation: 0,
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: scheme.primary, width: AppDimensions.buttonBorderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextStyles.labelLarge,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.labelMedium,
        ),
      ),

      // ── FilledButton ────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightLg),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextStyles.labelLarge,
          elevation: 0,
        ),
      ),

      // ── NavigationBar ───────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(0.16),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.labelSmall.copyWith(
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.lightOnSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? AppColors.primary
                : (isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant),
            size: AppDimensions.iconMd,
          );
        }),
      ),

      // ── BottomSheet ─────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLg),
          ),
        ),
      ),

      // ── Menus ───────────────────────────────────────────────────────────────
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
      ),

      canvasColor: surface,

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppDimensions.cardElevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: AppDimensions.cardBorderWidth,
          ),
        ),
      ),

      // ── Input ───────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: AppDimensions.inputBorderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: AppDimensions.inputBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(
            color: scheme.primary,
            width: AppDimensions.inputBorderWidth + 0.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.statusRed,
            width: AppDimensions.inputBorderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.statusRed,
            width: AppDimensions.inputBorderWidth + 0.5,
          ),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark
              ? AppColors.darkOnSurfaceVariant
              : AppColors.lightOnSurfaceVariant,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.darkDisabled : AppColors.lightDisabled,
        ),
        errorStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.statusRed,
        ),
        constraints: const BoxConstraints(minHeight: AppDimensions.inputHeight),
      ),

      // ── Chip ────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: onSurface),
        side: BorderSide(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space8,
          vertical: AppDimensions.space4,
        ),
      ),

      // ── BottomNavigationBar (legacy) ────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark
            ? AppColors.darkOnSurfaceVariant
            : AppColors.lightOnSurfaceVariant,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark
            ? AppColors.darkOutlineVariant
            : AppColors.lightOutlineVariant,
        thickness: AppDimensions.dividerThickness,
        space: 0,
      ),

      // ── Dialog ──────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        titleTextStyle:
            AppTextStyles.headlineSmall.copyWith(color: onSurface),
        contentTextStyle:
            AppTextStyles.bodyLarge.copyWith(color: onSurface),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightOnSurface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color:
              isDark ? AppColors.darkOnSurface : AppColors.lightBackground,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
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
        titleTextStyle:
            AppTextStyles.titleMedium.copyWith(color: onSurface),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: isDark
              ? AppColors.darkOnSurfaceVariant
              : AppColors.lightOnSurfaceVariant,
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
        side: BorderSide(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
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
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        extendedTextStyle: AppTextStyles.labelLarge,
      ),

      // ── Icons ─────────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: onSurface, size: AppDimensions.iconMd),
      primaryIconTheme:
          IconThemeData(color: scheme.primary, size: AppDimensions.iconMd),

      // ── TabBar ───────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark
            ? AppColors.darkOnSurfaceVariant
            : AppColors.lightOnSurfaceVariant,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
