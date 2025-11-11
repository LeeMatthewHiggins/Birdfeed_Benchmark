import 'package:dentity/dentity.dart';

final class BoundsComponent extends Component {
  BoundsComponent({
    required this.width,
    required this.height,
    required this.size,
  });

  final double width;
  final double height;
  final double size;

  @override
  BoundsComponent clone() => BoundsComponent(
        width: width,
        height: height,
        size: size,
      );

  @override
  int compareTo(dynamic other) {
    if (other is! BoundsComponent) return -1;
    final widthCompare = width.compareTo(other.width);
    if (widthCompare != 0) return widthCompare;
    final heightCompare = height.compareTo(other.height);
    if (heightCompare != 0) return heightCompare;
    return size.compareTo(other.size);
  }
}
