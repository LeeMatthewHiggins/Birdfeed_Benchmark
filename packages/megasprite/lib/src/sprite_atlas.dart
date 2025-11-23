import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class SpriteAtlas {
  const SpriteAtlas({
    required this.image,
  });

  final ui.Image image;

  ui.Image cloneImage() => image.clone();

  static Future<SpriteAtlas> fromAsset(String assetPath) async {
    final bytes = await _loadAssetBytes(assetPath);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return SpriteAtlas(image: image);
  }

  static Future<SpriteAtlas> fromBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return SpriteAtlas(image: image);
  }

  static Future<SpriteAtlas> fromImage(ui.Image image) async {
    return SpriteAtlas(image: image);
  }

  static Future<Uint8List> _loadAssetBytes(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List();
  }

  void dispose() {
    image.dispose();
  }
}
