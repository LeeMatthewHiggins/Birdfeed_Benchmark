import 'dart:ui';

class SpriteCellBinner {
  SpriteCellBinner({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.spriteCount,
    required this.cellSize,
  })  : gridColumns = (canvasWidth / cellSize).ceil(),
        gridRows = (canvasHeight / cellSize).ceil() {
    final totalCells = gridColumns * gridRows;
    _cellBins = List.generate(
      totalCells,
      (_) => List<int>.filled(_maxSpritesPerCell, 0),
      growable: false,
    );
    _cellCounts = List<int>.filled(totalCells, 0);
  }

  static const int _maxSpritesPerCell = 255;

  final double canvasWidth;
  final double canvasHeight;
  final int spriteCount;
  final int cellSize;
  final int gridColumns;
  final int gridRows;

  late final List<List<int>> _cellBins;
  late final List<int> _cellCounts;

  List<List<int>> get cellBins => _cellBins;

  int get totalCells => gridColumns * gridRows;

  int getCellCount(int cellIndex) => _cellCounts[cellIndex];

  void clear() {
    _cellCounts.fillRange(0, _cellCounts.length, 0);
  }

  void binSprite({
    required int spriteIndex,
    required Rect rect,
  }) {
    final minX = rect.left;
    final maxX = rect.right;
    final minY = rect.top;
    final maxY = rect.bottom;

    final cellSizeInv = 1.0 / cellSize;
    final rawMinCellX = (minX * cellSizeInv).floor();
    final rawMaxCellX = (maxX * cellSizeInv).floor();
    final rawMinCellY = (minY * cellSizeInv).floor();
    final rawMaxCellY = (maxY * cellSizeInv).floor();

    final maxColIndex = gridColumns - 1;
    final maxRowIndex = gridRows - 1;

    final minCellX = rawMinCellX < 0
        ? 0
        : (rawMinCellX > maxColIndex ? maxColIndex : rawMinCellX);
    final maxCellX = rawMaxCellX < 0
        ? 0
        : (rawMaxCellX > maxColIndex ? maxColIndex : rawMaxCellX);
    final minCellY = rawMinCellY < 0
        ? 0
        : (rawMinCellY > maxRowIndex ? maxRowIndex : rawMinCellY);
    final maxCellY = rawMaxCellY < 0
        ? 0
        : (rawMaxCellY > maxRowIndex ? maxRowIndex : rawMaxCellY);

    for (var cy = minCellY; cy <= maxCellY; cy++) {
      for (var cx = minCellX; cx <= maxCellX; cx++) {
        final cellIndex = cy * gridColumns + cx;
        final count = _cellCounts[cellIndex];
        if (count < _maxSpritesPerCell) {
          _cellBins[cellIndex][count] = spriteIndex;
          _cellCounts[cellIndex] = count + 1;
        }
        // Note: Sprites beyond 255 per cell are silently dropped
      }
    }
  }
}
