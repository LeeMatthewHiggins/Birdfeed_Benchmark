import 'package:flutter/foundation.dart';

@immutable
class FreeRect {
  const FreeRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  int get right => x + width;
  int get bottom => y + height;
  int get area => width * height;
  int get shortSide => width < height ? width : height;
  int get longSide => width > height ? width : height;

  bool canFit(int targetWidth, int targetHeight) {
    return targetWidth <= width && targetHeight <= height;
  }

  bool canFitRotated(int targetWidth, int targetHeight) {
    return targetHeight <= width && targetWidth <= height;
  }

  bool intersects(FreeRect other) {
    return x < other.right &&
        right > other.x &&
        y < other.bottom &&
        bottom > other.y;
  }

  bool contains(FreeRect other) {
    return x <= other.x &&
        y <= other.y &&
        right >= other.right &&
        bottom >= other.bottom;
  }

  List<FreeRect> splitBy(FreeRect placed) {
    if (!intersects(placed)) {
      return [this];
    }

    final result = <FreeRect>[];

    if (placed.x > x) {
      result.add(
        FreeRect(
          x: x,
          y: y,
          width: placed.x - x,
          height: height,
        ),
      );
    }

    if (placed.right < right) {
      result.add(
        FreeRect(
          x: placed.right,
          y: y,
          width: right - placed.right,
          height: height,
        ),
      );
    }

    if (placed.y > y) {
      result.add(
        FreeRect(
          x: x,
          y: y,
          width: width,
          height: placed.y - y,
        ),
      );
    }

    if (placed.bottom < bottom) {
      result.add(
        FreeRect(
          x: x,
          y: placed.bottom,
          width: width,
          height: bottom - placed.bottom,
        ),
      );
    }

    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreeRect &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}
