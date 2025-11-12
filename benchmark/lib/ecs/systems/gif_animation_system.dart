import 'package:dentity/dentity.dart';

import 'package:benchmark/ecs/components/gif_animation_state_component.dart';
import 'package:benchmark/ecs/components/gif_content_component.dart';

final class GifAnimationSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes => {GifContentComponent, GifAnimationStateComponent};

  @override
  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    final content =
        componentLists[GifContentComponent]?[entity] as GifContentComponent?;
    final state = componentLists[GifAnimationStateComponent]?[entity]
        as GifAnimationStateComponent?;

    if (content == null || state == null || content.frames.isEmpty) return;

    final deltaMillis = delta.inMilliseconds.toDouble();
    state.elapsedTime += deltaMillis;

    while (state.elapsedTime >= content.frameDurations[state.currentFrameIndex]) {
      state
        ..elapsedTime -= content.frameDurations[state.currentFrameIndex]
        ..currentFrameIndex = (state.currentFrameIndex + 1) % content.frames.length;
    }
  }
}
