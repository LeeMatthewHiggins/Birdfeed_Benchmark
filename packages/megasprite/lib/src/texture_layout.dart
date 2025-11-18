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
    cellDataWidth = MegaSpriteConfig.maxSpritesPerCell * 2;

    final totalPixelsNeeded = cellDataWidth * totalCells;
    final minSide = _nextPowerOf2((totalPixelsNeeded ~/ 8192).clamp(512, 8192));

    textureWidth = minSide;
    cellsPerRow = textureWidth ~/ cellDataWidth;

    final rowsNeeded = (totalCells / cellsPerRow).ceil();
    textureHeight = rowsNeeded;
  }

  int _nextPowerOf2(int n) {
    if (n <= 512) return 512;
    if (n <= 1024) return 1024;
    if (n <= 2048) return 2048;
    if (n <= 4096) return 4096;
    return 8192;
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
    final u = cellU + (spriteIndex * 2);
    return (u + 0.5) / textureWidth;
  }

  double getSpriteV(int cellIndex) {
    final v = getCellV(cellIndex);
    return (v + 0.5) / textureHeight;
  }
}
