import 'dart:ui';

class Sprite {
  const Sprite({
    required this.rect,
    required this.sourceRect,
    this.trimOffsetX = 0,
    this.trimOffsetY = 0,
    this.originalWidth,
    this.originalHeight,
    this.rotated = false,
  });

  factory Sprite.withTrimApplied({
    required double x,
    required double y,
    required double width,
    required double height,
    required Rect sourceRect,
    required int trimOffsetX,
    required int trimOffsetY,
    required int originalWidth,
    required int originalHeight,
    bool rotated = false,
  }) {
    final scale = width / sourceRect.width;
    final adjustedX = x + trimOffsetX * scale;
    final adjustedY = y + trimOffsetY * scale;

    return Sprite(
      rect: Rect.fromLTWH(adjustedX, adjustedY, width, height),
      sourceRect: sourceRect,
      trimOffsetX: trimOffsetX,
      trimOffsetY: trimOffsetY,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      rotated: rotated,
    );
  }

  final Rect rect;
  final Rect sourceRect;
  final int trimOffsetX;
  final int trimOffsetY;
  final int? originalWidth;
  final int? originalHeight;
  final bool rotated;

  bool get isTrimmed =>
      trimOffsetX != 0 ||
      trimOffsetY != 0 ||
      (originalWidth != null && originalWidth != rect.width.toInt()) ||
      (originalHeight != null && originalHeight != rect.height.toInt());

  Sprite copyWithPosition(double x, double y) {
    final scale = rect.width / sourceRect.width;
    final adjustedX = x + trimOffsetX * scale;
    final adjustedY = y + trimOffsetY * scale;

    return Sprite(
      rect: Rect.fromLTWH(adjustedX, adjustedY, rect.width, rect.height),
      sourceRect: sourceRect,
      trimOffsetX: trimOffsetX,
      trimOffsetY: trimOffsetY,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      rotated: rotated,
    );
  }

  Sprite copyWithSize(double width, double height) {
    final scale = width / sourceRect.width;
    final adjustedX = rect.left - trimOffsetX * (rect.width / sourceRect.width) + trimOffsetX * scale;
    final adjustedY = rect.top - trimOffsetY * (rect.height / sourceRect.height) + trimOffsetY * scale;

    return Sprite(
      rect: Rect.fromLTWH(adjustedX, adjustedY, width, height),
      sourceRect: sourceRect,
      trimOffsetX: trimOffsetX,
      trimOffsetY: trimOffsetY,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      rotated: rotated,
    );
  }
}
