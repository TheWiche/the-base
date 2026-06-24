/// Layout constants — spacing, radii, and touch-target sizes.
///
/// All interactive elements meet the 48dp minimum recommended by Material.
/// Primary actions (pay, confirm, open table) use 56–64dp to reduce mis-taps
/// on wet or gloved hands in the field.
abstract final class AppDimensions {
  // ── Spacing scale ──────────────────────────────────────────────────
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ── Page padding ───────────────────────────────────────────────────
  static const double pagePaddingH = 16.0;
  static const double pagePaddingV = 20.0;

  // ── Border radii ───────────────────────────────────────────────────
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0; // pill shape for status badges

  // ── Touch targets ──────────────────────────────────────────────────
  /// Minimum — text links, icon-only secondary actions.
  static const double tapTargetMin = 48.0;

  /// Standard — most interactive elements (chips, list items).
  static const double tapTargetStd = 56.0;

  /// Primary CTA — pay, confirm, open table, take photo.
  static const double tapTargetLg = 64.0;

  // ── Button sizes ───────────────────────────────────────────────────
  static const double buttonHeightSm = 44.0;
  static const double buttonHeightMd = 56.0;
  static const double buttonHeightLg = 64.0;
  static const double buttonBorderWidth = 2.0;

  // ── AppBar ─────────────────────────────────────────────────────────
  static const double appBarHeight = 64.0;
  static const double appBarElevation = 0.0;

  // ── Card ───────────────────────────────────────────────────────────
  static const double cardElevation = 0.0; // flat; use border for depth
  static const double cardBorderWidth = 1.5;

  // ── Status badge ───────────────────────────────────────────────────
  static const double badgePaddingH = 10.0;
  static const double badgePaddingV = 5.0;
  static const double badgeBorderRadius = radiusFull;

  // ── Bottom navigation ──────────────────────────────────────────────
  static const double bottomNavHeight = 72.0;

  // ── Icon sizes ─────────────────────────────────────────────────────
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ── Input fields ───────────────────────────────────────────────────
  static const double inputHeight = 56.0;
  static const double inputBorderWidth = 2.0;

  // ── El Radar / KDS item card ───────────────────────────────────────
  static const double radarCardMinHeight = 80.0;

  // ── Divider ────────────────────────────────────────────────────────
  static const double dividerThickness = 1.5;
}
