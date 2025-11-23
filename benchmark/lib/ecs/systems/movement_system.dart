import 'package:benchmark/ecs/components/position_component.dart';
import 'package:benchmark/ecs/components/velocity_component.dart';
import 'package:dentity/dentity.dart';

final class MovementSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes => {PositionComponent, VelocityComponent};

  @override
  void processEntity(
    Entity entity,
    ComponentManagerReadOnlyInterface componentManager,
    Duration delta,
  ) {
    final position = componentManager.getComponent<PositionComponent>(entity)!;
    final velocity = componentManager.getComponent<VelocityComponent>(entity)!;

    final deltaSeconds = delta.inMicroseconds / 1000000.0;

    position
      ..x += velocity.x * deltaSeconds
      ..y += velocity.y * deltaSeconds;
  }
}
