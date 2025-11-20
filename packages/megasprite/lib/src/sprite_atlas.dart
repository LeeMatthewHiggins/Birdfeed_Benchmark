import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class SpriteAtlas {
  const SpriteAtlas({
    required this.image,
    required this.shader,
  });

  final ui.Image image;
  final ui.FragmentShader shader;

  static Future<SpriteAtlas> fromAsset(String assetPath) async {
    final program = await ui.FragmentProgram.fromAsset(
      'packages/megasprite/shaders/sprite_shader.frag',
    );
    final shader = program.fragmentShader();

    final bytes = await _loadAssetBytes(assetPath);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return SpriteAtlas(image: image, shader: shader);
  }

  static Future<SpriteAtlas> fromBytes(Uint8List bytes) async {
    final program = await ui.FragmentProgram.fromAsset(
      'packages/megasprite/shaders/sprite_shader.frag',
    );
    final shader = program.fragmentShader();

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return SpriteAtlas(image: image, shader: shader);
  }

  static Future<SpriteAtlas> fromImage(ui.Image image) async {
    final program = await ui.FragmentProgram.fromAsset(
      'packages/megasprite/shaders/sprite_shader.frag',
    );
    final shader = program.fragmentShader();

    return SpriteAtlas(image: image, shader: shader);
  }

  static Future<Uint8List> _loadAssetBytes(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List();
  }

  void dispose() {
    image.dispose();
    shader.dispose();
  }
}
