import 'dart:io';

import 'package:flutter/services.dart';

/// Saves an image file into the device's public gallery
/// (Pictures/TheBase_Transferencias) so transfer receipts are visible in the
/// phone's gallery app — independent of the app-private copy used for in-app
/// display.
///
/// Backed by a native MethodChannel that uses MediaStore on Android 10+ and
/// the legacy public directory + media scan on older versions. Failures are
/// swallowed: the gallery copy is a convenience, never a blocker for the
/// payment write.
abstract final class GallerySaver {
  static const _channel = MethodChannel('com.thebase.app/gallery');

  /// Returns the saved URI/path on success, or null if it could not be saved.
  static Future<String?> saveImage({
    required String sourcePath,
    required String fileName,
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('saveToGallery', {
        'sourcePath': sourcePath,
        'fileName': fileName,
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
