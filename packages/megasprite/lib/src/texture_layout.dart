import 'package:flutter/foundation.dart';
import 'package:megasprite/src/config.dart';

class SpriteTextureLayout {
  SpriteTextureLayout({required this.totalCells}) {
    _calculateLayout();
  }

  final int totalCells;

  late final int dataTextureWidth;
  late final int dataTextureHeight;
  late final int cellDataWidth;

  void _calculateLayout() {
    // Each cell needs space for maxSpritesPerCell * pixelsPerSprite
    cellDataWidth =
        MegaSpriteConfig.maxSpritesPerCell * MegaSpriteConfig.pixelsPerSprite;

    // Use fixed width based on platform
    // Web: 4096, Native: 8192
    dataTextureWidth = kIsWeb ? 4096 : 8192;

    // Calculate total pixels needed for all cells
    final totalPixelsNeeded = totalCells * cellDataWidth;

    // Calculate height needed (round up)
    dataTextureHeight = (totalPixelsNeeded / dataTextureWidth).ceil();

    // Cap height at platform limits
    if (kIsWeb && dataTextureHeight > 4096) {
      dataTextureHeight = 4096;
    } else if (dataTextureHeight > 8192) {
      dataTextureHeight = 8192;
    }
  }

  // Get linear pixel offset for a cell's data
  int getCellPixelOffset(int cellIndex) {
    return cellIndex * cellDataWidth;
  }

  // Get U coordinate for a sprite within a cell
  double getSpriteU(int cellIndex, int spriteIndex) {
    final pixelOffset = getCellPixelOffset(cellIndex) +
        (spriteIndex * MegaSpriteConfig.pixelsPerSprite);
    final u = pixelOffset % dataTextureWidth;
    return (u + 0.5) / dataTextureWidth;
  }

  // Get V coordinate for a sprite within a cell
  double getSpriteV(int cellIndex, int spriteIndex) {
    final pixelOffset = getCellPixelOffset(cellIndex) +
        (spriteIndex * MegaSpriteConfig.pixelsPerSprite);
    final v = pixelOffset ~/ dataTextureWidth;
    return (v + 0.5) / dataTextureHeight;
  }
}
