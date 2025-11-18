import 'dart:ui';

class Sprite {
  const Sprite({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.sourceRect,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final Rect sourceRect;
}
