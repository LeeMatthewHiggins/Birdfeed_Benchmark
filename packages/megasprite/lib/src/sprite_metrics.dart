class SpriteMetrics {
  const SpriteMetrics({
    required this.avgSpritesPerCell,
    required this.maxSpritesPerCell,
    required this.textureWidth,
    required this.textureHeight,
    required this.gridColumns,
    required this.gridRows,
    required this.cellCounts,
  });

  final double avgSpritesPerCell;
  final int maxSpritesPerCell;
  final int textureWidth;
  final int textureHeight;
  final int gridColumns;
  final int gridRows;
  final List<int> cellCounts;
}
