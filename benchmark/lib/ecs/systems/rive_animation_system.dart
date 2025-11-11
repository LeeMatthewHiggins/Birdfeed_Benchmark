import 'package:dentity/dentity.dart' as dentity;

import 'package:benchmark/ecs/components/rive_content_component.dart';

final class RiveAnimationSystem extends dentity.EntitySystem {
  @override
  Set<Type> get filterTypes => {RiveContentComponent};

  @override
  void processEntity(
    dentity.Entity entity,
    Map<Type, dentity.SparseList<dentity.Component>> componentLists,
    Duration delta,
  ) {
    final content = componentLists[RiveContentComponent]?[entity]
        as RiveContentComponent?;

    if (content == null) return;

    final deltaSeconds = delta.inMicroseconds / 1000000.0;

    if (!content.offsetApplied) {
      if (content.stateMachine != null) {
        content.stateMachine!.advanceAndApply(content.animationOffset);
      } else {
        content.artboard.advance(content.animationOffset);
      }
      content.offsetApplied = true;
    }

    if (content.stateMachine != null) {
      content.stateMachine!.advanceAndApply(deltaSeconds);
    } else {
      content.artboard.advance(deltaSeconds);
    }
  }
}
