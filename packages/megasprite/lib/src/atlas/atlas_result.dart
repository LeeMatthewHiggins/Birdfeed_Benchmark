import 'package:megasprite/src/atlas/atlas_page.dart';
import 'package:megasprite/src/sprite.dart';
import 'package:megasprite/src/sprite_atlas.dart';

class AtlasResult {
  const AtlasResult({
    required this.pages,
    required this.totalSpriteCount,
    required this.uniqueSpriteCount,
    required this.duplicateCount,
  });

  final List<AtlasPage> pages;
  final int totalSpriteCount;
  final int uniqueSpriteCount;
  final int duplicateCount;

  int get pageCount => pages.length;

  double get overallEfficiency {
    if (pages.isEmpty) return 0;

    var totalUsedArea = 0;
    var totalAtlasArea = 0;

    for (final page in pages) {
      totalAtlasArea += page.width * page.height;
      for (final sprite in page.packedSprites) {
        totalUsedArea += sprite.packedWidth * sprite.packedHeight;
      }
    }

    if (totalAtlasArea == 0) return 0;
    return totalUsedArea / totalAtlasArea;
  }

  List<SpriteAtlas> toSpriteAtlasList() {
    return pages.map((page) => page.toSpriteAtlas()).toList();
  }

  Map<String, SpriteLocation> toSpriteLocationMap() {
    final map = <String, SpriteLocation>{};

    for (final page in pages) {
      for (final packed in page.packedSprites) {
        map[packed.identifier] = SpriteLocation(
          pageIndex: page.pageIndex,
          sprite: page.toSpriteMap()[packed.identifier]!,
          trimOffsetX: packed.frame.trimRect.offsetX,
          trimOffsetY: packed.frame.trimRect.offsetY,
          originalWidth: packed.frame.trimRect.originalWidth,
          originalHeight: packed.frame.trimRect.originalHeight,
          rotated: packed.rotated,
        );
      }

      for (final alias in page.aliases) {
        final packed = alias.packedSprite;
        map[alias.identifier] = SpriteLocation(
          pageIndex: page.pageIndex,
          sprite: page.toSpriteMap()[alias.identifier]!,
          trimOffsetX: packed.frame.trimRect.offsetX,
          trimOffsetY: packed.frame.trimRect.offsetY,
          originalWidth: packed.frame.trimRect.originalWidth,
          originalHeight: packed.frame.trimRect.originalHeight,
          rotated: packed.rotated,
        );
      }
    }

    return map;
  }

  void dispose() {
    for (final page in pages) {
      page.dispose();
    }
  }
}

class SpriteLocation {
  const SpriteLocation({
    required this.pageIndex,
    required this.sprite,
    required this.trimOffsetX,
    required this.trimOffsetY,
    required this.originalWidth,
    required this.originalHeight,
    required this.rotated,
  });

  final int pageIndex;
  final Sprite sprite;
  final int trimOffsetX;
  final int trimOffsetY;
  final int originalWidth;
  final int originalHeight;
  final bool rotated;
}
