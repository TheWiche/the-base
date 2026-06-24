/// Immutable financial parameters for the Bonanza business domain.
///
/// These values must NEVER be changed without explicit business owner approval.
/// All monetary values are in Colombian Pesos (COP) as integers (no decimals).
abstract final class FinancialConstants {
  // ── Waiter Base ────────────────────────────────────────────────────

  /// Every waiter starts each shift with this base amount in COP.
  static const int initialBase = 300000;

  /// Manual base increases happen exclusively in this fixed increment.
  static const int baseIncrement = 100000;

  // ── Liquor Rule ────────────────────────────────────────────────────

  /// Marker used to identify liquor-category products.
  /// Liquor cost → added to waiter's debt, NOT subtracted from base balance.
  static const String liquorCategoryId = 'licores';

  // ── Cierre Blindado thresholds ─────────────────────────────────────

  /// A daily report cannot be generated if pending Radar items exceed this.
  static const int maxAllowedPendingRadarItems = 0;

  // ── Payment ────────────────────────────────────────────────────────

  /// Minimum transfer amount that requires a photo receipt.
  static const int transferPhotoThreshold = 0; // all transfers require photo

  // ── Verification codes ─────────────────────────────────────────────

  /// Length of the SHA-256-derived numeric verification code shown to the
  /// cashier after a transfer is legalized.
  static const int verificationCodeLength = 8;
}
