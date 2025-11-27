class TrimRect {
  const TrimRect({
    required this.originalWidth,
    required this.originalHeight,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  const TrimRect.empty()
      : originalWidth = 0,
        originalHeight = 0,
        x = 0,
        y = 0,
        width = 0,
        height = 0;

  factory TrimRect.untrimmed({required int width, required int height}) {
    return TrimRect(
      originalWidth: width,
      originalHeight: height,
      x: 0,
      y: 0,
      width: width,
      height: height,
    );
  }

  final int originalWidth;
  final int originalHeight;
  final int x;
  final int y;
  final int width;
  final int height;

  int get offsetX => x;
  int get offsetY => y;

  bool get isEmpty => width == 0 || height == 0;

  bool get isTrimmed =>
      x != 0 ||
      y != 0 ||
      width != originalWidth ||
      height != originalHeight;
}
