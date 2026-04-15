import 'dart:io';

import 'package:gallery_saver_plus/gallery_saver.dart';

class GalleryService {
  static const String _albumName = 'wlog';

  Future<bool> saveImageToGallery(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return false;

    try {
      final saved = await GallerySaver.saveImage(
        imagePath,
        albumName: _albumName,
      );
      return saved == true;
    } catch (_) {
      return false;
    }
  }
}
