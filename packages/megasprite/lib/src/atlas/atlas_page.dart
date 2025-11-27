import 'dart:ui' as ui;

import 'package:megasprite/src/models/packed_sprite.dart';
import 'package:megasprite/src/sprite.dart';
import 'package:megasprite/src/sprite_atlas.dart';

class AtlasPage {
  const AtlasPage({
    required this.image,
    required this.packedSprites,
    required this.aliases,
    required this.pageIndex,
    required this.width,
    required this.height,
  });

  final ui.Image image;
  final List<PackedSprite> packedSprites;
  final List<SpriteAlias> aliases;
  final int pageIndex;
  final int width;
  final int height;

  int get spriteCount => packedSprites.length + aliases.length;

  SpriteAtlas toSpriteAtlas() => SpriteAtlas(image: image);

  Map<String, Sprite> toSpriteMap() {
    final map = <String, Sprite>{};

    for (final packed in packedSprites) {
      final trimRect = packed.frame.trimRect;
      map[packed.identifier] = Sprite(
        rect: ui.Rect.fromLTWH(
          packed.x.toDouble(),
          packed.y.toDouble(),
          packed.packedWidth.toDouble(),
          packed.packedHeight.toDouble(),
        ),
        sourceRect: ui.Rect.fromLTWH(
          packed.x.toDouble(),
          packed.y.toDouble(),
          packed.packedWidth.toDouble(),
          packed.packedHeight.toDouble(),
        ),
        trimOffsetX: trimRect.offsetX,
        trimOffsetY: trimRect.offsetY,
        originalWidth: trimRect.originalWidth,
        originalHeight: trimRect.originalHeight,
        rotated: packed.rotated,
      );
    }

    for (final alias in aliases) {
      final packed = alias.packedSprite;
      final trimRect = packed.frame.trimRect;
      map[alias.identifier] = Sprite(
        rect: ui.Rect.fromLTWH(
          packed.x.toDouble(),
          packed.y.toDouble(),
          packed.packedWidth.toDouble(),
          packed.packedHeight.toDouble(),
        ),
        sourceRect: ui.Rect.fromLTWH(
          packed.x.toDouble(),
          packed.y.toDouble(),
          packed.packedWidth.toDouble(),
          packed.packedHeight.toDouble(),
        ),
        trimOffsetX: trimRect.offsetX,
        trimOffsetY: trimRect.offsetY,
        originalWidth: trimRect.originalWidth,
        originalHeight: trimRect.originalHeight,
        rotated: packed.rotated,
      );
    }

    return map;
  }

  void dispose() {
    image.dispose();
  }
}
