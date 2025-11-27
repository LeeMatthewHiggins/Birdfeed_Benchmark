import 'package:megasprite/src/models/packed_sprite.dart';
import 'package:megasprite/src/models/sprite_frame.dart';

class PackingResult {
  const PackingResult({
    required this.packed,
    required this.overflow,
    required this.usedWidth,
    required this.usedHeight,
  });

  final List<PackedSprite> packed;
  final List<SpriteFrame> overflow;
  final int usedWidth;
  final int usedHeight;

  double get efficiency {
    if (usedWidth == 0 || usedHeight == 0) return 0;
    final totalArea = usedWidth * usedHeight;
    var usedArea = 0;
    for (final sprite in packed) {
      usedArea += sprite.packedWidth * sprite.packedHeight;
    }
    return usedArea / totalArea;
  }
}

abstract class PackingStrategy {
  PackingResult pack({
    required List<SpriteFrame> sprites,
    required int atlasWidth,
    required int atlasHeight,
    required int padding,
    required bool allowRotation,
    required int pageIndex,
  });

  void reset();
}
