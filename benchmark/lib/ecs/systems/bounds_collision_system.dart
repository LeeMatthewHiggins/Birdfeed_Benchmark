import 'package:benchmark/ecs/components/bounds_component.dart';
import 'package:benchmark/ecs/components/position_component.dart';
import 'package:benchmark/ecs/components/velocity_component.dart';
import 'package:dentity/dentity.dart';

final class BoundsCollisionSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes =>
      {PositionComponent, VelocityComponent, BoundsComponent};

  @override
  void processEntity(
    Entity entity,
    ComponentManagerReadOnlyInterface componentManager,
    Duration delta,
  ) {
    final position = componentManager.getComponent<PositionComponent>(entity)!;
    final velocity = componentManager.getComponent<VelocityComponent>(entity)!;
    final bounds = componentManager.getComponent<BoundsComponent>(entity)!;

    final halfSize = bounds.size / 2;
    final maxX = bounds.width;
    final maxY = bounds.height;

    final posX = position.x;
    final posY = position.y;

    if (posX - halfSize <= 0) {
      position.x = halfSize;
      if (velocity.x < 0) velocity.x = -velocity.x;
    } else if (posX + halfSize >= maxX) {
      position.x = maxX - halfSize;
      if (velocity.x > 0) velocity.x = -velocity.x;
    }

    if (posY - halfSize <= 0) {
      position.y = halfSize;
      if (velocity.y < 0) velocity.y = -velocity.y;
    } else if (posY + halfSize >= maxY) {
      position.y = maxY - halfSize;
      if (velocity.y > 0) velocity.y = -velocity.y;
    }
  }
}
