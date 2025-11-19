class SpriteMetrics {
  const SpriteMetrics({
    required this.avgSpritesPerCell,
    required this.maxSpritesPerCell,
    required this.positionTextureWidth,
    required this.positionTextureHeight,
    required this.gridColumns,
    required this.gridRows,
    required this.cellCounts,
  });

  final double avgSpritesPerCell;
  final int maxSpritesPerCell;
  final int positionTextureWidth;
  final int positionTextureHeight;
  final int gridColumns;
  final int gridRows;
  final List<int> cellCounts;
}
