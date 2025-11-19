import 'package:megasprite/src/config.dart';

class SpriteTextureLayout {
  SpriteTextureLayout({required this.totalCells}) {
    _calculateLayout();
  }

  final int totalCells;

  late final int textureWidth;
  late final int textureHeight;
  late final int cellsPerRow;
  late final int cellDataWidth;

  void _calculateLayout() {
    cellDataWidth = MegaSpriteConfig.maxSpritesPerCell * MegaSpriteConfig.pixelsPerSprite;

    final minWidth = _nextPowerOf2(cellDataWidth);
    var bestWidth = minWidth;
    var bestHeight = 16384;
    var bestWaste = double.infinity;

    for (var testWidth = minWidth; testWidth <= 16384; testWidth = testWidth * 2) {
      final cellsInRow = testWidth ~/ cellDataWidth;
      if (cellsInRow == 0) continue;

      final rowsNeeded = (totalCells / cellsInRow).ceil();
      final testHeight = _nextPowerOf2(rowsNeeded);

      final totalPixels = testWidth * testHeight;
      final usedPixels = cellDataWidth * totalCells;
      final waste = totalPixels - usedPixels;

      if (waste < bestWaste) {
        bestWaste = waste.toDouble();
        bestWidth = testWidth;
        bestHeight = testHeight;
      }
    }

    textureWidth = bestWidth;
    cellsPerRow = textureWidth ~/ cellDataWidth;
    textureHeight = bestHeight;
  }

  int _nextPowerOf2(int n) {
    if (n <= 1) return 1;
    return 1 << (n - 1).bitLength;
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
    return (u + 0.5) / textureWidth;
  }

  double getSpriteV(int cellIndex) {
    final v = getCellV(cellIndex);
    return (v + 0.5) / textureHeight;
  }
}
