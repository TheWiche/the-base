import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

/// Singleton wrapper around the Isar database instance.
///
/// Initialization is called once in [main] before [runApp].
/// All features access the shared instance via [IsarService.instance].
///
/// Schemas are passed at initialization time. As new features are added,
/// their Isar collection schema classes are appended to the [schemas] list
/// in [main.dart] — this keeps the service decoupled from feature internals.
///
/// Example (main.dart):
/// ```dart
/// await IsarService.initialize(schemas: [
///   WaiterBaseSchema,
///   BaseIncreaseSchema,
///   ProductSchema,
///   OrderItemSchema,
///   TransferSchema,
/// ]);
/// ```
final class IsarService {
  IsarService._();

  static Isar? _isar;

  static Isar get instance {
    assert(
      _isar != null,
      'IsarService.initialize() must be called before accessing the instance.',
    );
    return _isar!;
  }

  static bool get isInitialized => _isar != null;

  static Future<void> initialize({
    required List<CollectionSchema<dynamic>> schemas,
    String name = 'bonanza',
  }) async {
    if (_isar != null && _isar!.isOpen) return;

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      schemas,
      directory: dir.path,
      name: name,
      inspector: true, // disable in production builds via --dart-define
    );
  }

  /// Closes the database. Call only in tests or on sign-out flows.
  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  /// Wipes all data. ONLY for testing. Throws in release mode.
  static Future<void> clearAllForTesting() async {
    assert(
      () {
        return true;
      }(),
      'clearAllForTesting must not be called in release mode.',
    );
    await _isar?.writeTxn(() async => _isar!.clear());
  }
}
