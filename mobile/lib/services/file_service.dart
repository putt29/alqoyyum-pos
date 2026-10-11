import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Menyimpan / membagikan berkas (PNG struk, PDF/Excel laporan).
class FileService {
  FileService._();

  static Future<File> writeTemp(String name, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Simpan PNG ke galeri (album "AL-QOYYUM").
  static Future<void> savePngToGallery(Uint8List bytes, String fileName) async {
    final file = await writeTemp(fileName, bytes);
    await Gal.putImage(file.path, album: 'AL-QOYYUM');
  }

  static Future<void> shareBytes(Uint8List bytes, String fileName, String mimeType, {String? text}) async {
    final file = await writeTemp(fileName, bytes);
    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)], text: text);
  }
}
