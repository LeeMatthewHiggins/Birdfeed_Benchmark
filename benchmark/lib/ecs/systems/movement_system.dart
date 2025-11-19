import 'package:dentity/dentity.dart';

import 'package:benchmark/ecs/components/position_component.dart';
import 'package:benchmark/ecs/components/velocity_component.dart';

final class MovementSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes => {PositionComponent, VelocityComponent};

  @override
  void processEntity(
    Entity entity,
    EntityComposition composition,
    Duration delta,
  ) {
    final position = composition.get<PositionComponent>(entity)!;
    final velocity = composition.get<VelocityComponent>(entity)!;

    final deltaSeconds = delta.inMicroseconds / 1000000.0;

    position
      ..x += velocity.x * deltaSeconds
      ..y += velocity.y * deltaSeconds;
  }
}
