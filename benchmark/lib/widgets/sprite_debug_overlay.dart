import 'package:flutter/material.dart';

class SpriteDebugMetrics {
  const SpriteDebugMetrics({
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

class SpriteDebugOverlay extends StatelessWidget {
  const SpriteDebugOverlay({
    required this.metrics,
    required this.cellSize,
    super.key,
  });

  final SpriteDebugMetrics metrics;
  final int cellSize;

  static const Color _kMetricsBackgroundColor = Color(0xCC000000);
  static const Color _kMetricsTextColor = Colors.white;
  static const double _kMetricsFontSize = 14;
  static const double _kMetricsPadding = 12;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: _CellGridPainter(
            metrics: metrics,
            cellSize: cellSize,
          ),
          size: Size.infinite,
        ),
        Positioned(
          top: _kMetricsPadding,
          right: _kMetricsPadding,
          child: Container(
            padding: const EdgeInsets.all(_kMetricsPadding),
            decoration: BoxDecoration(
              color: _kMetricsBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetric('Grid', '${metrics.gridColumns}x${metrics.gridRows}'),
                _buildMetric('Texture', '${metrics.textureWidth}x${metrics.textureHeight}'),
                _buildMetric('Avg/Cell', metrics.avgSpritesPerCell.toStringAsFixed(1)),
                _buildMetric('Max/Cell', '${metrics.maxSpritesPerCell}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: _kMetricsTextColor,
              fontSize: _kMetricsFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.green,
              fontSize: _kMetricsFontSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _CellGridPainter extends CustomPainter {
  _CellGridPainter({
    required this.metrics,
    required this.cellSize,
  });

  final SpriteDebugMetrics metrics;
  final int cellSize;

  static const int _kHighlightThreshold = 200;
  static const Color _kGridColor = Color(0x40FFFFFF);
  static const Color _kHighlightColor = Color(0x80FF0000);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _kGridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final highlightPaint = Paint()
      ..color = _kHighlightColor
      ..style = PaintingStyle.fill;

    for (var y = 0; y < metrics.gridRows; y++) {
      for (var x = 0; x < metrics.gridColumns; x++) {
        final cellIndex = y * metrics.gridColumns + x;
        final count = metrics.cellCounts[cellIndex];

        final left = x * cellSize.toDouble();
        final top = y * cellSize.toDouble();
        final right = (left + cellSize).clamp(0.0, size.width);
        final bottom = (top + cellSize).clamp(0.0, size.height);

        if (count > _kHighlightThreshold) {
          canvas.drawRect(
            Rect.fromLTRB(left, top, right, bottom),
            highlightPaint,
          );
        }

        canvas.drawRect(
          Rect.fromLTRB(left, top, right, bottom),
          gridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CellGridPainter oldDelegate) =>
      oldDelegate.metrics != metrics || oldDelegate.cellSize != cellSize;
}
