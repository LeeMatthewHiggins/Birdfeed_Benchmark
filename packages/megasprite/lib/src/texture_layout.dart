import 'package:megasprite/src/config.dart';

class SpriteTextureLayout {
  SpriteTextureLayout({required this.totalCells}) {
    _calculateLayout();
  }

  final int totalCells;

  late final int dataTextureWidth;
  late final int dataTextureHeight;
  late final int cellsPerRow;
  late final int cellDataWidth;

  void _calculateLayout() {
    cellDataWidth =
        MegaSpriteConfig.maxSpritesPerCell * MegaSpriteConfig.pixelsPerSprite;

    const availableSizes = [
      (256, 256),
      (512, 256),
      (512, 512),
      (1024, 512),
      (1024, 1024),
      (2048, 1024),
      (2048, 2048),
      (4096, 2048),
      (4096, 4096),
      (8192, 4096),
      (8192, 8192),
    ];

    final textureSizes = List<(int, int)>.from(availableSizes)
      ..sort((a, b) => (a.$1 * a.$2).compareTo(b.$1 * b.$2));

    for (final (width, height) in textureSizes) {
      final cellsInRow = width ~/ cellDataWidth;
      if (cellsInRow == 0) continue;

      final rowsNeeded = (totalCells / cellsInRow).ceil();

      if (rowsNeeded <= height) {
        dataTextureWidth = width;
        dataTextureHeight = height;
        cellsPerRow = cellsInRow;
        return;
      }
    }

    dataTextureWidth = 8192;
    dataTextureHeight = 8192;
    cellsPerRow = dataTextureWidth ~/ cellDataWidth;
  }

  int getCellU(int cellIndex) {
    final col = cellIndex % cellsPerRow;
    return col * cellDataWidth;
  }

  int getCellV(int cellIndex) {
    return cellIndex ~/ cellsPerRow;
  }

  double getSpriteU(int cellIndex, int spriteIndex) {
    final cellU = getCellU(cellIndex);
    final u = cellU + (spriteIndex * MegaSpriteConfig.pixelsPerSprite);
    return (u + 0.5) / dataTextureWidth;
  }

  double getSpriteV(int cellIndex) {
    final v = getCellV(cellIndex);
    return (v + 0.5) / dataTextureHeight;
  }
}
