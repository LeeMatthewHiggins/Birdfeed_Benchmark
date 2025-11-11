import 'package:dentity/dentity.dart';

final class PositionComponent extends Component {
  PositionComponent({required this.x, required this.y});

  double x;
  double y;

  @override
  PositionComponent clone() => PositionComponent(x: x, y: y);

  @override
  int compareTo(dynamic other) {
    if (other is! PositionComponent) return -1;
    final xCompare = x.compareTo(other.x);
    if (xCompare != 0) return xCompare;
    return y.compareTo(other.y);
  }
}
