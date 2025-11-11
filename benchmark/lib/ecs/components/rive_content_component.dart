import 'package:dentity/dentity.dart' as dentity;
import 'package:rive/rive.dart';

final class RiveContentComponent extends dentity.Component {
  RiveContentComponent({
    required this.artboard,
    required this.stateMachine,
    required this.animationOffset,
  });

  final Artboard artboard;
  final StateMachine? stateMachine;
  final double animationOffset;
  bool offsetApplied = false;

  @override
  RiveContentComponent clone() => RiveContentComponent(
        artboard: artboard,
        stateMachine: stateMachine,
        animationOffset: animationOffset,
      );

  @override
  int compareTo(dynamic other) {
    if (other is! RiveContentComponent) return -1;
    return animationOffset.compareTo(other.animationOffset);
  }

  void dispose() {
    stateMachine?.dispose();
    artboard.dispose();
  }
}
