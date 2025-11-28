import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

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

  static const double _rotationAngle = -math.pi / 2;
  static final double _rotationCos = math.cos(_rotationAngle);
  static final double _rotationSin = math.sin(_rotationAngle);

  final VoidCallback? onBeforePaint;

  final List<Sprite> sprites;
  final SpriteAtlas atlas;
  final Paint _paint = Paint();

  Float32List _transforms = Float32List(0);
  Float32List _rects = Float32List(0);
  ui.Image? _clonedImage;

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

    _clonedImage ??= atlas.image.clone();

    _ensureBuffers(sprites.length);

    var tIndex = 0;
    var rIndex = 0;

    for (final sprite in sprites) {
      final src = sprite.sourceRect;

      if (sprite.rotated) {
        final scale = sprite.rect.width / src.height;
        final scos = scale * _rotationCos;
        final ssin = scale * _rotationSin;

        final anchorX = src.width / 2;
        final anchorY = src.height / 2;
        final destCenterX = sprite.rect.left + sprite.rect.width / 2;
        final destCenterY = sprite.rect.top + sprite.rect.height / 2;
        final tx = destCenterX - scos * anchorX + ssin * anchorY;
        final ty = destCenterY - ssin * anchorX - scos * anchorY;

        _transforms[tIndex++] = scos;
        _transforms[tIndex++] = ssin;
        _transforms[tIndex++] = tx;
        _transforms[tIndex++] = ty;
      } else {
        final scale = sprite.rect.width / src.width;

        _transforms[tIndex++] = scale;
        _transforms[tIndex++] = 0;
        _transforms[tIndex++] = sprite.rect.left;
        _transforms[tIndex++] = sprite.rect.top;
      }

      _rects[rIndex++] = src.left;
      _rects[rIndex++] = src.top;
      _rects[rIndex++] = src.right;
      _rects[rIndex++] = src.bottom;
    }

    canvas.drawRawAtlas(
      _clonedImage!,
      _transforms,
      _rects,
      null,
      null,
      null,
      _paint,
    );
  }

  void dispose() {
    _clonedImage?.dispose();
    _clonedImage = null;
  }

  @override
  bool shouldRepaint(MegaSpriteAtlasPainter oldDelegate) {
    if (oldDelegate.atlas != atlas) {
      _clonedImage?.dispose();
      _clonedImage = null;
    }
    return oldDelegate.sprites != sprites || oldDelegate.atlas != atlas;
  }
}
