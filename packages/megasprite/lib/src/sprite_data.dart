import 'package:megasprite/src/sprite_effect.dart';

class SpriteData {
  const SpriteData({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.atlasX,
    required this.atlasY,
    required this.atlasWidth,
    required this.atlasHeight,
    this.trimOffsetX = 0,
    this.trimOffsetY = 0,
    this.originalWidth,
    this.originalHeight,
    this.rotated = false,
    this.effect = SpriteEffect.none,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double atlasX;
  final double atlasY;
  final double atlasWidth;
  final double atlasHeight;
  final double trimOffsetX;
  final double trimOffsetY;
  final double? originalWidth;
  final double? originalHeight;
  final bool rotated;
  final SpriteEffect effect;
}
