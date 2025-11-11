import 'package:dentity/dentity.dart';

import 'package:benchmark/ecs/components/gif_content_component.dart';

final class GifAnimationSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes => {GifContentComponent};

  @override
  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    final content =
        componentLists[GifContentComponent]?[entity] as GifContentComponent?;

    if (content == null || content.frames.isEmpty) return;

    final deltaMillis = delta.inMilliseconds.toDouble();
    content.elapsedTime += deltaMillis;

    while (content.elapsedTime >=
        content.frameDurations[content.currentFrameIndex]) {
      content
        ..elapsedTime -= content.frameDurations[content.currentFrameIndex]
        ..currentFrameIndex =
            (content.currentFrameIndex + 1) % content.frames.length;
    }
  }
}
