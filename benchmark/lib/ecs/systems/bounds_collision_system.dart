import 'package:dentity/dentity.dart';

import 'package:benchmark/ecs/components/bounds_component.dart';
import 'package:benchmark/ecs/components/position_component.dart';
import 'package:benchmark/ecs/components/velocity_component.dart';

final class BoundsCollisionSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes =>
      {PositionComponent, VelocityComponent, BoundsComponent};

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
    final bounds =
        componentLists[BoundsComponent]?[entity] as BoundsComponent?;

    if (position == null || velocity == null || bounds == null) return;

    final halfSize = bounds.size / 2;

    if (position.x - halfSize <= 0) {
      position.x = halfSize;
      velocity.x = velocity.x.abs();
    } else if (position.x + halfSize >= bounds.width) {
      position.x = bounds.width - halfSize;
      velocity.x = -velocity.x.abs();
    }

    if (position.y - halfSize <= 0) {
      position.y = halfSize;
      velocity.y = velocity.y.abs();
    } else if (position.y + halfSize >= bounds.height) {
      position.y = bounds.height - halfSize;
      velocity.y = -velocity.y.abs();
    }
  }
}
