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

    // Calculate total pixels needed for all cells
    final totalPixelsNeeded = totalCells * cellDataWidth;

    // Find the most square texture dimensions
    const maxDimension = kIsWeb ? 4096 : 8192;

    // Try different widths to find the most square aspect ratio
    var bestWidth = maxDimension;
    var bestHeight = maxDimension;
    var bestAspectRatio = double.infinity;

    final widths = kIsWeb
        ? [256, 512, 1024, 2048, 4096]
        : [256, 512, 1024, 2048, 4096, 8192];

    for (final width in widths) {
      final height = (totalPixelsNeeded / width).ceil();

      // Skip if height exceeds platform limit
      if (height > maxDimension) continue;

      // Calculate aspect ratio (always >= 1.0)
      final aspectRatio = height > width ? height / width : width / height;

      // Prefer more square textures
      if (aspectRatio < bestAspectRatio) {
        bestAspectRatio = aspectRatio;
        bestWidth = width;
        bestHeight = height;
      }
    }

    dataTextureWidth = bestWidth;
    dataTextureHeight = bestHeight;
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
