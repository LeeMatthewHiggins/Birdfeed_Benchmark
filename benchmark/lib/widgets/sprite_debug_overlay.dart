import 'package:flutter/material.dart';
import 'package:megasprite/megasprite.dart';

class SpriteDebugOverlay extends StatelessWidget {
  const SpriteDebugOverlay({
    required this.metrics,
    required this.cellSize,
    super.key,
  });

  final SpriteMetrics metrics;
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
          bottom: _kMetricsPadding,
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
                _buildMetric(
                    'Grid', '${metrics.gridColumns}x${metrics.gridRows}'),
                _buildMetric('Data Texture',
                    '${metrics.positionTextureWidth}x${metrics.positionTextureHeight}'),
                _buildMetric(
                    'Avg/Cell', metrics.avgSpritesPerCell.toStringAsFixed(1)),
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

  final SpriteMetrics metrics;
  final int cellSize;

  static const Color _kGridColor = Color(0x40FFFFFF);
  static const int _kMaxSpritesPerCell = 255;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _kGridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var y = 0; y < metrics.gridRows; y++) {
      for (var x = 0; x < metrics.gridColumns; x++) {
        final cellIndex = y * metrics.gridColumns + x;
        final count = metrics.cellCounts[cellIndex];

        final left = x * cellSize.toDouble();
        final top = y * cellSize.toDouble();
        final right = (left + cellSize).clamp(0.0, size.width);
        final bottom = (top + cellSize).clamp(0.0, size.height);

        // Calculate color gradient from green (empty) to red (full)
        if (count > 0) {
          final ratio = (count / _kMaxSpritesPerCell).clamp(0.0, 1.0);
          final fillPaint = Paint()
            ..color = Color.lerp(
              const Color(0x8000FF00), // Green with alpha
              const Color(0x80FF0000), // Red with alpha
              ratio,
            )!
            ..style = PaintingStyle.fill;

          canvas.drawRect(
            Rect.fromLTRB(left, top, right, bottom),
            fillPaint,
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
