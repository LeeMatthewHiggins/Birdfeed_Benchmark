import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:megasprite/src/sprite.dart';
import 'package:megasprite/src/sprite_atlas.dart';

class MegaSpriteAtlasPainter extends CustomPainter {
  MegaSpriteAtlasPainter({
    required this.sprites,
    required this.atlas,
    this.onBeforePaint,
    super.repaint,
  });

  final VoidCallback? onBeforePaint;

  final List<Sprite> sprites;
  final SpriteAtlas atlas;
  final Paint _paint = Paint();

  // Buffers to avoid allocation
  Float32List _transforms = Float32List(0);
  Float32List _rects = Float32List(0);

  void _ensureBuffers(int count) {
    if (_transforms.length != count * 4) {
      _transforms = Float32List(count * 4);
      _rects = Float32List(count * 4);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    onBeforePaint?.call();
    if (sprites.isEmpty) return;

    _ensureBuffers(sprites.length);

    var tIndex = 0;
    var rIndex = 0;

    for (final sprite in sprites) {
      final scale = sprite.rect.width / sprite.sourceRect.width;

      // RSTransform(scos, ssin, tx, ty)
      // sprite.rect.left/top now represents top-left corner
      _transforms[tIndex++] = scale;
      _transforms[tIndex++] = 0;
      _transforms[tIndex++] = sprite.rect.left;
      _transforms[tIndex++] = sprite.rect.top;

      // Rect(left, top, right, bottom)
      final src = sprite.sourceRect;
      _rects[rIndex++] = src.left;
      _rects[rIndex++] = src.top;
      _rects[rIndex++] = src.right;
      _rects[rIndex++] = src.bottom;
    }

    canvas.drawRawAtlas(
      atlas.image,
      _transforms,
      _rects,
      null,
      null,
      null,
      _paint,
    );
  }

  @override
  bool shouldRepaint(MegaSpriteAtlasPainter oldDelegate) =>
      oldDelegate.sprites != sprites || oldDelegate.atlas != atlas;
}
