import 'package:shared_preferences/shared_preferences.dart';

/// Monotonically-increasing table number counter persisted in SharedPreferences.
///
/// Once a number is issued it is never reused — even if the corresponding table
/// session is later closed or deleted. This guarantees a strict +1 sequence
/// across the lifetime of the app on the device.
final class TableCounterService {
  static const _key = 'thebase_table_counter';

  /// Returns the next table number and persists it atomically.
  ///
  /// Idempotency note: the counter is incremented immediately on call, not on
  /// confirmation. Cancelled dialogs leave a gap in the sequence, which is
  /// acceptable per the business requirement ("never reuse").
  Future<int> nextTableNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key) ?? 0;
    final next = current + 1;
    await prefs.setInt(_key, next);
    return next;
  }

  /// Reads the counter without incrementing — used to preview the next number
  /// in the "Nueva Mesa" dialog before the user confirms.
  Future<int> peekNextTableNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_key) ?? 0) + 1;
  }

  /// Ensures the stored counter is at least [minimum].
  ///
  /// Called during app startup to migrate existing installations: sets the
  /// counter to the highest table number already in Isar so the first new
  /// table gets max+1, never a recycled number.
  Future<void> ensureMinimum(int minimum) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key) ?? 0;
    if (current < minimum) {
      await prefs.setInt(_key, minimum);
    }
  }
}
