import 'package:benchmark/ecs/components/gif_animation_state_component.dart';
import 'package:benchmark/ecs/components/gif_content_component.dart';
import 'package:dentity/dentity.dart';

final class GifAnimationSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes =>
      {GifContentComponent, GifAnimationStateComponent};

  @override
  void processEntity(
    Entity entity,
    ComponentManagerReadOnlyInterface componentManager,
    Duration delta,
  ) {
    final content = componentManager.getComponent<GifContentComponent>(entity)!;
    final state =
        componentManager.getComponent<GifAnimationStateComponent>(entity)!;

    if (content.frames.isEmpty) return;

    final deltaMillis = delta.inMilliseconds.toDouble();
    state.elapsedTime += deltaMillis;

    final frameDurations = content.frameDurations;
    final frameCount = content.frames.length;

    while (state.elapsedTime >= frameDurations[state.currentFrameIndex]) {
      state
        ..elapsedTime -= frameDurations[state.currentFrameIndex]
        ..currentFrameIndex = (state.currentFrameIndex + 1) % frameCount;
    }
  }
}
