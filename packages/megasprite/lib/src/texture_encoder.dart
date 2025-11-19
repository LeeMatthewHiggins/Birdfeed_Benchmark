import 'dart:typed_data';

import 'package:megasprite/src/cell_binner.dart';
import 'package:megasprite/src/config.dart';
import 'package:megasprite/src/sprite_data.dart';
import 'package:megasprite/src/texture_layout.dart';

class SpriteTextureEncoder {
  SpriteTextureEncoder({
    required this.binner,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.layout,
    required this.maxGridColumns,
    required this.maxGridRows,
  }) {
    final positionPixelCount = layout.dataTextureWidth * layout.dataTextureHeight * 4;
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

    for (var cellY = 0; cellY < binner.gridRows; cellY++) {
      for (var cellX = 0; cellX < binner.gridColumns; cellX++) {
        final cellIndex = cellY * binner.gridColumns + cellX;
        final spritesInCell = binner.cellBins[cellIndex];
        final cellSpriteCount = binner.getCellCount(cellIndex);

        final startIndex = (cellSpriteCount > MegaSpriteConfig.maxSpritesPerCell)
            ? cellSpriteCount - MegaSpriteConfig.maxSpritesPerCell
            : 0;
        final endIndex = cellSpriteCount;

        final cellTopLeftX = cellX * binner.cellSize;
        final cellTopLeftY = cellY * binner.cellSize;

        final cellU = layout.getCellU(cellIndex);
        final cellV = layout.getCellV(cellIndex);

        var encodedCount = 0;

        for (var i = startIndex; i < endIndex; i++) {
          final spriteIndex = spritesInCell[i];
          final sprite = sprites[spriteIndex];

          if (sprite == null) continue;

          final cellRelativeX = sprite.x - cellTopLeftX;
          final cellRelativeY = sprite.y - cellTopLeftY;

          final byteX = (cellRelativeX + MegaSpriteConfig.signedByteOffset).round().clamp(0, 255);
          final byteY = (cellRelativeY + MegaSpriteConfig.signedByteOffset).round().clamp(0, 255);
          final byteWidth = sprite.width.round().clamp(0, 255);
          final byteHeight = sprite.height.round().clamp(0, 255);

          final atlasX = sprite.atlasX.round().clamp(0, 65535);
          final atlasY = sprite.atlasY.round().clamp(0, 65535);
          final atlasWidth = sprite.atlasWidth.round().clamp(0, 65535);
          final atlasHeight = sprite.atlasHeight.round().clamp(0, 65535);

          final pixelU = cellU + (encodedCount * MegaSpriteConfig.pixelsPerSprite);
          final pixelV = cellV;
          final pixelIndex = (pixelV * layout.dataTextureWidth + pixelU) * 4;

          pixels[pixelIndex] = byteX;
          pixels[pixelIndex + 1] = byteY;
          pixels[pixelIndex + 2] = byteWidth;
          pixels[pixelIndex + 3] = byteHeight;

          final pixelIndex2 = pixelIndex + 4;
          pixels[pixelIndex2] = atlasX % 256;
          pixels[pixelIndex2 + 1] = atlasX ~/ 256;
          pixels[pixelIndex2 + 2] = atlasY % 256;
          pixels[pixelIndex2 + 3] = atlasY ~/ 256;

          final pixelIndex3 = pixelIndex + 8;
          pixels[pixelIndex3] = atlasWidth % 256;
          pixels[pixelIndex3 + 1] = atlasWidth ~/ 256;
          pixels[pixelIndex3 + 2] = atlasHeight % 256;
          pixels[pixelIndex3 + 3] = atlasHeight ~/ 256;

          encodedCount++;
        }

        actualCounts[cellIndex] = encodedCount;
      }
    }

    return pixels;
  }

  Uint8List encodeCellCountData(List<int> actualCounts) {
    final pixelCount = maxGridColumns * maxGridRows * 4;
    final pixels = _cellCountPixels..fillRange(0, pixelCount, 0);

    for (var cellY = 0; cellY < binner.gridRows; cellY++) {
      for (var cellX = 0; cellX < binner.gridColumns; cellX++) {
        final cellIndex = cellY * binner.gridColumns + cellX;
        final count = actualCounts[cellIndex];

        pixels[cellIndex * 4] = count;
        pixels[cellIndex * 4 + 1] = 0;
        pixels[cellIndex * 4 + 2] = 0;
        pixels[cellIndex * 4 + 3] = 255;
      }
    }

    return pixels;
  }
}
