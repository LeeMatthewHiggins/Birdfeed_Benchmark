import 'package:dentity/dentity.dart';

import 'package:benchmark/ecs/components/position_component.dart';
import 'package:benchmark/ecs/components/velocity_component.dart';

final class MovementSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes => {PositionComponent, VelocityComponent};

  @override
  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    final position =
        componentLists[PositionComponent]?[entity] as PositionComponent?;
    final velocity =
        componentLists[VelocityComponent]?[entity] as VelocityComponent?;

    if (position == null || velocity == null) return;

    final deltaSeconds = delta.inMicroseconds / 1000000.0;

    position
      ..x += velocity.x * deltaSeconds
      ..y += velocity.y * deltaSeconds;
  }
}
