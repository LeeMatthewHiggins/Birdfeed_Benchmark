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

          final originalWidth = sprite.maxX - sprite.minX;
          final originalHeight = sprite.maxY - sprite.minY;

          final clampedWidth = clampedMaxX - clampedMinX;
          final clampedHeight = clampedMaxY - clampedMinY;

          final uvOffsetX = (clampedMinX - originalCellRelativeMinX) / originalWidth;
          final uvOffsetY = (clampedMinY - originalCellRelativeMinY) / originalHeight;

          final uvScaleX = clampedWidth / originalWidth;
          final uvScaleY = clampedHeight / originalHeight;

          final adjustedSrcX = sprite.srcX + (uvOffsetX * sprite.srcWidth);
          final adjustedSrcY = sprite.srcY + (uvOffsetY * sprite.srcHeight);
          final adjustedSrcW = sprite.srcWidth * uvScaleX;
          final adjustedSrcH = sprite.srcHeight * uvScaleY;

          final byteMinX = (clampedMinX + MegaSpriteConfig.signedByteOffset).round();
          final byteMinY = (clampedMinY + MegaSpriteConfig.signedByteOffset).round();
          final byteMaxX = (clampedMaxX + MegaSpriteConfig.signedByteOffset).round();
          final byteMaxY = (clampedMaxY + MegaSpriteConfig.signedByteOffset).round();

          final rawSrcByteX = (adjustedSrcX * 255).round();
          final rawSrcByteY = (adjustedSrcY * 255).round();
          final rawSrcByteW = (adjustedSrcW * 255).round();
          final rawSrcByteH = (adjustedSrcH * 255).round();

          final srcByteX = rawSrcByteX < 0 ? 0 : (rawSrcByteX > 255 ? 255 : rawSrcByteX);
          final srcByteY = rawSrcByteY < 0 ? 0 : (rawSrcByteY > 255 ? 255 : rawSrcByteY);
          final srcByteW = rawSrcByteW < 0 ? 0 : (rawSrcByteW > 255 ? 255 : rawSrcByteW);
          final srcByteH = rawSrcByteH < 0 ? 0 : (rawSrcByteH > 255 ? 255 : rawSrcByteH);

          final pixelU = cellU + (encodedCount * 2);
          final pixelV = cellV;
          final pixelIndex = (pixelV * layout.textureWidth + pixelU) * 4;

          pixels[pixelIndex] = byteMinX;
          pixels[pixelIndex + 1] = byteMinY;
          pixels[pixelIndex + 2] = byteMaxX;
          pixels[pixelIndex + 3] = byteMaxY;

          final pixelIndex2 = pixelIndex + 4;
          pixels[pixelIndex2] = srcByteX;
          pixels[pixelIndex2 + 1] = srcByteY;
          pixels[pixelIndex2 + 2] = srcByteW;
          pixels[pixelIndex2 + 3] = srcByteH;

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
