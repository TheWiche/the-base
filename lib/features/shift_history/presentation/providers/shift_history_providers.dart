import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../../core/database/isar_service.dart';
import '../../data/models/shift_snapshot.dart';

/// All saved [ShiftSnapshot]s, newest first. Re-fetched on each mount.
final shiftHistoryProvider =
    FutureProvider.autoDispose<List<ShiftSnapshot>>((ref) async {
  final snapshots = await IsarService.db.shiftSnapshots.where().anyId().findAll();
  snapshots.sort((a, b) => b.snapshotAt.compareTo(a.snapshotAt));
  return snapshots;
});

/// A single [ShiftSnapshot] by its Isar id — for the detail screen.
final shiftSnapshotByIdProvider =
    FutureProvider.autoDispose.family<ShiftSnapshot?, int>((ref, id) async {
  return IsarService.db.shiftSnapshots.get(id);
});
