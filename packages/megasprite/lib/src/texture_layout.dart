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
    cellDataWidth =
        MegaSpriteConfig.maxSpritesPerCell * MegaSpriteConfig.pixelsPerSprite;

    const maxDimension = kIsWeb ? 4096 : 8192;

    final widths = kIsWeb
        ? [1024, 2048, 4096]
        : [1024, 2048, 4096, 8192];

    var bestWidth = maxDimension;
    var bestHeight = maxDimension;
    var bestAspectRatio = double.infinity;

    for (final width in widths) {
      if (width < cellDataWidth) continue;

      final height = totalCells;

      if (height > maxDimension) continue;

      final aspectRatio = height > width ? height / width : width / height;

      if (aspectRatio < bestAspectRatio) {
        bestAspectRatio = aspectRatio;
        bestWidth = width;
        bestHeight = height;
      }
    }

    dataTextureWidth = bestWidth;
    dataTextureHeight = bestHeight;
  }

  int getCellPixelOffset(int cellIndex) {
    return cellIndex * dataTextureWidth;
  }

  double getSpriteU(int cellIndex, int spriteIndex) {
    final u = spriteIndex * MegaSpriteConfig.pixelsPerSprite;
    return (u + 0.5) / dataTextureWidth;
  }

  double getSpriteV(int cellIndex, int spriteIndex) {
    return (cellIndex + 0.5) / dataTextureHeight;
  }
}
