import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Applies [quarterTurns] × 90° clockwise rotation to the JPEG at [sourcePath].
/// Returns [sourcePath] unchanged if no rotation is needed.
/// Writes the rotated image to a session-scoped temp file.
Future<String> applyPhotoRotation(String sourcePath, int quarterTurns) async {
  if (quarterTurns == 0) return sourcePath;
  final bytes = await File(sourcePath).readAsBytes();
  final decoded = img.decodeJpg(bytes);
  if (decoded == null) return sourcePath;
  final rotated = img.copyRotate(decoded, angle: (quarterTurns * 90) % 360);
  final tmpDir = await getTemporaryDirectory();
  final outPath =
      '${tmpDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await File(outPath).writeAsBytes(img.encodeJpg(rotated, quality: 85));
  return outPath;
}
