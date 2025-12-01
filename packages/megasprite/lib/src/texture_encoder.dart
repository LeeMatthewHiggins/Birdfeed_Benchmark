import 'dart:typed_data';

import 'package:megasprite/src/cell_binner.dart';
import 'package:megasprite/src/config.dart';
import 'package:megasprite/src/sprite_data.dart';
import 'package:megasprite/src/texture_layout.dart';

/// Encodes sprite data into texture pixels for GPU-based sprite rendering.
///
/// Each sprite uses 3 pixels (12 bytes) in the position data texture:
///
/// Pixel 0 (Position & Size):
///   R: relative X position (signed byte + 128 offset)
///   G: relative Y position (signed byte + 128 offset)
///   B: sprite width (0-255)
///   A: sprite height (0-255)
///
/// Pixel 1 (Atlas Position):
///   R: atlas X low byte
///   G: atlas X high byte
///   B: atlas Y low byte
///   A: atlas Y high byte
///
/// Pixel 2 (Atlas Size & Flags):
///   R: atlas width low byte
///   G: atlas width high byte [bits 0-4: high bits, bit 5: rotated, bit 6: flipX, bit 7: flipY]
///   B: atlas height low byte
///   A: atlas height high byte [bits 0-4: high bits, bits 5-7: effect]
class SpriteTextureEncoder {
  SpriteTextureEncoder({
    required this.binner,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.layout,
    required this.maxGridColumns,
    required this.maxGridRows,
  }) {
    final positionPixelCount =
        layout.dataTextureWidth * layout.dataTextureHeight * 4;
    _positionPixels = Uint8List(positionPixelCount);

    final cellCountPixelCount = maxGridColumns * maxGridRows * 4;
    _cellCountPixels = Uint8List(cellCountPixelCount);
  }

  final SpriteCellBinner binner;
  final double canvasWidth;
  final double canvasHeight;
  final SpriteTextureLayout layout;
  final int maxGridColumns;
  final int maxGridRows;

  late final Uint8List _positionPixels;
  late final Uint8List _cellCountPixels;

  Uint8List encodePositionData(
    List<SpriteData?> sprites,
    List<int> actualCounts,
  ) {
    final pixels = _positionPixels;
    final gridColumns = binner.gridColumns;
    final gridRows = binner.gridRows;
    final cellSize = binner.cellSize;
    final cellBins = binner.cellBins;
    final dataTextureWidth = layout.dataTextureWidth;
    const maxSprites = MegaSpriteConfig.maxSpritesPerCell;
    const pixelsPerSprite = MegaSpriteConfig.pixelsPerSprite;
    const signedOffset = MegaSpriteConfig.signedByteOffset;

    for (var cellY = 0; cellY < gridRows; cellY++) {
      for (var cellX = 0; cellX < gridColumns; cellX++) {
        final cellIndex = cellY * gridColumns + cellX;
        final spritesInCell = cellBins[cellIndex];
        final cellSpriteCount = binner.getCellCount(cellIndex);

        final startIndex =
            cellSpriteCount > maxSprites ? cellSpriteCount - maxSprites : 0;

        final cellTopLeftX = cellX * cellSize;
        final cellTopLeftY = cellY * cellSize;

        var encodedCount = 0;

        for (var i = startIndex; i < cellSpriteCount; i++) {
          final sprite = sprites[spritesInCell[i]];
          if (sprite == null) continue;

          final relX = (sprite.x - cellTopLeftX + signedOffset).toInt();
          final relY = (sprite.y - cellTopLeftY + signedOffset).toInt();

          final byteX = relX < 0 ? 0 : (relX > 255 ? 255 : relX);
          final byteY = relY < 0 ? 0 : (relY > 255 ? 255 : relY);
          final byteWidth = sprite.width.toInt() & 0xFF;
          final byteHeight = sprite.height.toInt() & 0xFF;

          final atlasX = sprite.atlasX.toInt();
          final atlasY = sprite.atlasY.toInt();
          final atlasWidth = sprite.atlasWidth.toInt();
          final atlasHeight = sprite.atlasHeight.toInt();

          final pixelU = encodedCount * pixelsPerSprite;
          final pixelV = cellIndex;
          final pixelBase = (pixelV * dataTextureWidth + pixelU) * 4;

          pixels[pixelBase] = byteX;
          pixels[pixelBase + 1] = byteY;
          pixels[pixelBase + 2] = byteWidth;
          pixels[pixelBase + 3] = byteHeight;

          pixels[pixelBase + 4] = atlasX & 0xFF;
          pixels[pixelBase + 5] = atlasX >> 8;
          pixels[pixelBase + 6] = atlasY & 0xFF;
          pixels[pixelBase + 7] = atlasY >> 8;

          final rotationFlag =
              sprite.rotated ? MegaSpriteConfig.rotationBitMask : 0;
          final flipXFlag = sprite.flipX ? MegaSpriteConfig.flipXBitMask : 0;
          final flipYFlag = sprite.flipY ? MegaSpriteConfig.flipYBitMask : 0;
          final effectBits = (sprite.effect.value & 0x07)
              << MegaSpriteConfig.effectBitShift;

          pixels[pixelBase + 8] = atlasWidth & 0xFF;
          pixels[pixelBase + 9] =
              ((atlasWidth >> 8) & 0x1F) | rotationFlag | flipXFlag | flipYFlag;
          pixels[pixelBase + 10] = atlasHeight & 0xFF;
          pixels[pixelBase + 11] = ((atlasHeight >> 8) & 0x1F) | effectBits;

          encodedCount++;
        }

        actualCounts[cellIndex] = encodedCount;
      }
    }

    return pixels;
  }

  Uint8List encodeCellCountData(List<int> actualCounts) {
    final pixels = _cellCountPixels;

    for (var cellY = 0; cellY < binner.gridRows; cellY++) {
      for (var cellX = 0; cellX < binner.gridColumns; cellX++) {
        final cellIndex = cellY * binner.gridColumns + cellX;
        final count = actualCounts[cellIndex];

        final pixelBase = cellIndex * 4;
        pixels[pixelBase] = count;
        pixels[pixelBase + 1] = 0;
        pixels[pixelBase + 2] = 0;
        pixels[pixelBase + 3] = 255;
      }
    }

    return pixels;
  }
}
