import 'package:dentity/dentity.dart';

final class GifAnimationStateComponent extends Component {
  GifAnimationStateComponent({
    this.currentFrameIndex = 0,
    this.elapsedTime = 0,
  });

  int currentFrameIndex;
  double elapsedTime;

  @override
  GifAnimationStateComponent clone() => GifAnimationStateComponent(
        currentFrameIndex: currentFrameIndex,
        elapsedTime: elapsedTime,
      );

  @override
  int compareTo(dynamic other) {
    if (other is! GifAnimationStateComponent) return -1;
    return currentFrameIndex.compareTo(other.currentFrameIndex);
  }
}
