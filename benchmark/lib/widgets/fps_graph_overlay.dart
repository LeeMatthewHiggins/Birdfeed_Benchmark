import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:benchmark/services/fps_tracker.dart';

class FpsGraphOverlay extends StatefulWidget {
  const FpsGraphOverlay({
    required this.fpsTracker,
    super.key,
  });

  final FpsTracker fpsTracker;

  @override
  State<FpsGraphOverlay> createState() => _FpsGraphOverlayState();
}

class _FpsGraphOverlayState extends State<FpsGraphOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  static const _updateInterval = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _updateInterval,
    )..repeat();

    _animationController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        width: 200,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFpsText(),
            const SizedBox(height: 4),
            Expanded(
              child: CustomPaint(
                painter: _FpsGraphPainter(
                  fpsHistory: widget.fpsTracker.fpsHistory,
                ),
                child: Container(),
              ),
            ),
            const SizedBox(height: 4),
            _buildStatsText(),
          ],
        ),
      ),
    );
  }

  Widget _buildFpsText() {
    final fps = widget.fpsTracker.currentFps;
    final color = _getFpsColor(fps);

    return Text(
      '${fps.toStringAsFixed(1)} FPS',
      style: TextStyle(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatsText() {
    final avg = widget.fpsTracker.averageFps;
    final min = widget.fpsTracker.minFps;
    final max = widget.fpsTracker.maxFps;

    return Text(
      'Avg: ${avg.toStringAsFixed(1)} | '
      'Min: ${min.toStringAsFixed(0)} | '
      'Max: ${max.toStringAsFixed(0)}',
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 10,
      ),
    );
  }

  Color _getFpsColor(double fps) {
    if (fps > 59) return Colors.green;
    if (fps >= 30) return Colors.yellow;
    return Colors.red;
  }
}

class _FpsGraphPainter extends CustomPainter {
  _FpsGraphPainter({required this.fpsHistory});

  final List<double> fpsHistory;

  static const double _maxFps = 60;
  static const double _midFps = 30;

  @override
  void paint(Canvas canvas, Size size) {
    if (fpsHistory.isEmpty) return;

    _drawReferenceLines(canvas, size);
    _drawFpsGraph(canvas, size);
  }

  void _drawReferenceLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    final y60 = size.height * (1 - _maxFps / _maxFps);
    canvas.drawLine(
      Offset(0, y60),
      Offset(size.width, y60),
      paint,
    );

    final y30 = size.height * (1 - _midFps / _maxFps);
    canvas.drawLine(
      Offset(0, y30),
      Offset(size.width, y30),
      paint,
    );
  }

  void _drawFpsGraph(Canvas canvas, Size size) {
    if (fpsHistory.length < 2) return;

    final averageFps = fpsHistory.reduce((a, b) => a + b) / fpsHistory.length;

    final path = Path();
    final paint = Paint()
      ..color = _getFpsColor(averageFps)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stepX = size.width / (fpsHistory.length - 1);

    for (var i = 0; i < fpsHistory.length; i++) {
      final fps = math.min(fpsHistory[i], _maxFps);
      final x = i * stepX;
      final y = size.height * (1 - fps / _maxFps);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  Color _getFpsColor(double fps) {
    if (fps > 59) return Colors.green;
    if (fps >= 30) return Colors.yellow;
    return Colors.red;
  }

  @override
  bool shouldRepaint(_FpsGraphPainter oldDelegate) {
    return oldDelegate.fpsHistory != fpsHistory;
  }
}
