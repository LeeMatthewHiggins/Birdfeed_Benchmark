import 'package:dentity/dentity.dart';

final class VelocityComponent extends Component {
  VelocityComponent({required this.x, required this.y});

  double x;
  double y;

  @override
  VelocityComponent clone() => VelocityComponent(x: x, y: y);

  @override
  int compareTo(dynamic other) {
    if (other is! VelocityComponent) return -1;
    final xCompare = x.compareTo(other.x);
    if (xCompare != 0) return xCompare;
    return y.compareTo(other.y);
  }
}
