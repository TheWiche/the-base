import 'package:intl/intl.dart';

/// COP (Colombian Peso) currency formatting extensions.
///
/// Colombia uses period as the thousands separator and comma as the decimal
/// separator — the opposite of en-US. All monetary values in Bonanza are
/// stored as integers (centavos are not used), so decimal display is omitted.
extension CopFormatX on int {
  static final NumberFormat _cop = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  /// Full COP format: `$300.000`
  String get toCop => _cop.format(this);

  /// Compact COP format: `$300k`  (useful in tight UI spaces like badges).
  String get toCopCompact => _compact.format(this);

  /// Absolute value formatted as COP (useful for displaying debts without sign).
  String get toAbsCop => _cop.format(abs());

  /// Sign-aware: shows `+$100.000` or `-$50.000`.
  String get toSignedCop {
    final formatted = _cop.format(abs());
    return this >= 0 ? '+$formatted' : '-$formatted';
  }

  /// True if this represents a zero balance.
  bool get isZeroBalance => this == 0;

  /// True if this is a positive balance.
  bool get isPositive => this > 0;

  /// True if this represents a debt.
  bool get isDebt => this < 0;
}

extension NullableIntCopX on int? {
  /// Returns `$0` for null values — safe for display without null checks.
  String get toCopSafe => (this ?? 0).toCop;
}
