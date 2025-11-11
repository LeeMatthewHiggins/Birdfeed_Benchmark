import 'package:flutter/material.dart';

class CheckerboardBackground extends StatelessWidget {
  const CheckerboardBackground({
    this.checkerSize = 20,
    this.darkColor = const Color(0xFF2A2A2A),
    this.lightColor = const Color(0xFF333333),
    super.key,
  });

  final double checkerSize;
  final Color darkColor;
  final Color lightColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CheckerboardPainter(
        checkerSize: checkerSize,
        darkColor: darkColor,
        lightColor: lightColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  _CheckerboardPainter({
    required this.checkerSize,
    required this.darkColor,
    required this.lightColor,
  });

  final double checkerSize;
  final Color darkColor;
  final Color lightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / checkerSize).ceil();
    final rows = (size.height / checkerSize).ceil();

    final darkPaint = Paint()..color = darkColor;
    final lightPaint = Paint()..color = lightColor;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final paint = (row + col).isEven ? darkPaint : lightPaint;

        canvas.drawRect(
          Rect.fromLTWH(
            col * checkerSize,
            row * checkerSize,
            checkerSize,
            checkerSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter oldDelegate) =>
      oldDelegate.checkerSize != checkerSize ||
      oldDelegate.darkColor != darkColor ||
      oldDelegate.lightColor != lightColor;
}
