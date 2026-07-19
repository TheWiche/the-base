import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Carpeta donde se guardan las fotos de transferencias (mesas y captura suelta).
Future<Directory> transferPhotosDir() async {
  final Directory base;
  if (!kIsWeb && Platform.isAndroid) {
    base = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
  } else {
    base = await getApplicationDocumentsDirectory();
  }
  final dir = Directory('${base.path}/Bonanza_Transferencias');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

/// Lista las imágenes guardadas (jpg/png), más recientes primero.
Future<List<File>> listTransferPhotos() async {
  final dir = await transferPhotosDir();
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) {
        final p = f.path.toLowerCase();
        return p.endsWith('.jpg') || p.endsWith('.jpeg') || p.endsWith('.png');
      })
      .toList()
    ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files;
}
