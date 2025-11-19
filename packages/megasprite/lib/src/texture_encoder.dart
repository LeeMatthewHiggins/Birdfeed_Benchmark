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
    final positionPixelCount = layout.textureWidth * layout.textureHeight * 4;
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

  static const double _minBound = -128;
  static const double _maxBound = 127;

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

          final originalCellRelativeMinX = sprite.minX - cellTopLeftX;
          final originalCellRelativeMinY = sprite.minY - cellTopLeftY;
          final originalCellRelativeMaxX = sprite.maxX - cellTopLeftX;
          final originalCellRelativeMaxY = sprite.maxY - cellTopLeftY;

          final clampedMinX = originalCellRelativeMinX < _minBound
              ? _minBound
              : (originalCellRelativeMinX > _maxBound ? _maxBound : originalCellRelativeMinX);
          final clampedMinY = originalCellRelativeMinY < _minBound
              ? _minBound
              : (originalCellRelativeMinY > _maxBound ? _maxBound : originalCellRelativeMinY);
          final clampedMaxX = originalCellRelativeMaxX < _minBound
              ? _minBound
              : (originalCellRelativeMaxX > _maxBound ? _maxBound : originalCellRelativeMaxX);
          final clampedMaxY = originalCellRelativeMaxY < _minBound
              ? _minBound
              : (originalCellRelativeMaxY > _maxBound ? _maxBound : originalCellRelativeMaxY);

          final byteMinX = (clampedMinX + MegaSpriteConfig.signedByteOffset).round();
          final byteMinY = (clampedMinY + MegaSpriteConfig.signedByteOffset).round();
          final byteMaxX = (clampedMaxX + MegaSpriteConfig.signedByteOffset).round();
          final byteMaxY = (clampedMaxY + MegaSpriteConfig.signedByteOffset).round();

          final atlasMinX = sprite.atlasMinX.round().clamp(0, 65535);
          final atlasMinY = sprite.atlasMinY.round().clamp(0, 65535);
          final atlasMaxX = sprite.atlasMaxX.round().clamp(0, 65535);
          final atlasMaxY = sprite.atlasMaxY.round().clamp(0, 65535);

          final pixelU = cellU + (encodedCount * MegaSpriteConfig.pixelsPerSprite);
          final pixelV = cellV;
          final pixelIndex = (pixelV * layout.textureWidth + pixelU) * 4;

          pixels[pixelIndex] = byteMinX;
          pixels[pixelIndex + 1] = byteMinY;
          pixels[pixelIndex + 2] = byteMaxX;
          pixels[pixelIndex + 3] = byteMaxY;

          final pixelIndex2 = pixelIndex + 4;
          pixels[pixelIndex2] = atlasMinX & 0xFF;
          pixels[pixelIndex2 + 1] = (atlasMinX >> 8) & 0xFF;
          pixels[pixelIndex2 + 2] = atlasMinY & 0xFF;
          pixels[pixelIndex2 + 3] = (atlasMinY >> 8) & 0xFF;

          final pixelIndex3 = pixelIndex + 8;
          pixels[pixelIndex3] = atlasMaxX & 0xFF;
          pixels[pixelIndex3 + 1] = (atlasMaxX >> 8) & 0xFF;
          pixels[pixelIndex3 + 2] = atlasMaxY & 0xFF;
          pixels[pixelIndex3 + 3] = (atlasMaxY >> 8) & 0xFF;

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
