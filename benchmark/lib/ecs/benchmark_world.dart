import 'dart:math';

import 'package:dentity/dentity.dart';

import 'package:benchmark/ecs/components/bounds_component.dart';
import 'package:benchmark/ecs/components/gif_animation_state_component.dart';
import 'package:benchmark/ecs/components/gif_content_component.dart';
import 'package:benchmark/ecs/components/position_component.dart';
import 'package:benchmark/ecs/components/rive_content_component.dart';
import 'package:benchmark/ecs/components/sprite_rect_component.dart';
import 'package:benchmark/ecs/components/sprite_shader_content_component.dart';
import 'package:benchmark/ecs/components/velocity_component.dart';
import 'package:benchmark/ecs/systems/bounds_collision_system.dart';
import 'package:benchmark/ecs/systems/gif_animation_system.dart';
import 'package:benchmark/ecs/systems/movement_system.dart';

final class BenchmarkWorld {
  BenchmarkWorld() {
    final componentManager = ComponentManager(
      archetypeManagerFactory: ArchetypeManagerBigInt.new,
      componentArrayFactories: {
        PositionComponent: ContiguousSparseList<PositionComponent>.new,
        VelocityComponent: ContiguousSparseList<VelocityComponent>.new,
        BoundsComponent: ContiguousSparseList<BoundsComponent>.new,
        RiveContentComponent: ContiguousSparseList<RiveContentComponent>.new,
        GifContentComponent: ContiguousSparseList<GifContentComponent>.new,
        GifAnimationStateComponent:
            ContiguousSparseList<GifAnimationStateComponent>.new,
        SpriteShaderContentComponent:
            ContiguousSparseList<SpriteShaderContentComponent>.new,
        SpriteRectComponent: ContiguousSparseList<SpriteRectComponent>.new,
      },
    );

    final entityManager = EntityManager(componentManager);

    _world = World(
      componentManager,
      entityManager,
      [
        MovementSystem(),
        BoundsCollisionSystem(),
        GifAnimationSystem(),
      ],
    );
  }

  late final World _world;

  static const double _instanceSize = 100;
  static const double _minVelocity = 50;
  static const double _maxVelocity = 200;

  Entity createRiveEntity({
    required RiveContentComponent content,
    required double boundsWidth,
    required double boundsHeight,
  }) {
    final random = Random();
    final x = random.nextDouble() * boundsWidth;
    final y = random.nextDouble() * boundsHeight;
    final velocityX =
        (_minVelocity + random.nextDouble() * (_maxVelocity - _minVelocity)) *
            (random.nextBool() ? 1 : -1);
    final velocityY =
        (_minVelocity + random.nextDouble() * (_maxVelocity - _minVelocity)) *
            (random.nextBool() ? 1 : -1);

    return _world.createEntity({
      PositionComponent(x: x, y: y),
      VelocityComponent(x: velocityX, y: velocityY),
      BoundsComponent(
        width: boundsWidth,
        height: boundsHeight,
        size: _instanceSize,
      ),
      content,
    });
  }

  Entity createGifEntity({
    required GifContentComponent content,
    required double boundsWidth,
    required double boundsHeight,
  }) {
    final random = Random();
    final x = random.nextDouble() * boundsWidth;
    final y = random.nextDouble() * boundsHeight;
    final velocityX =
        (_minVelocity + random.nextDouble() * (_maxVelocity - _minVelocity)) *
            (random.nextBool() ? 1 : -1);
    final velocityY =
        (_minVelocity + random.nextDouble() * (_maxVelocity - _minVelocity)) *
            (random.nextBool() ? 1 : -1);

    final initialFrameIndex = random.nextInt(content.frames.length);
    final initialElapsedTime = random.nextDouble() *
        content.frameDurations[initialFrameIndex];

    return _world.createEntity({
      PositionComponent(x: x, y: y),
      VelocityComponent(x: velocityX, y: velocityY),
      BoundsComponent(
        width: boundsWidth,
        height: boundsHeight,
        size: _instanceSize,
      ),
      content,
      GifAnimationStateComponent(
        currentFrameIndex: initialFrameIndex,
        elapsedTime: initialElapsedTime,
      ),
    });
  }

  Entity createSpriteShaderEntity({
    required SpriteShaderContentComponent content,
    required SpriteRectComponent spriteRect,
    required double boundsWidth,
    required double boundsHeight,
    required double spriteSize,
  }) {
    final random = Random();
    final x = random.nextDouble() * boundsWidth;
    final y = random.nextDouble() * boundsHeight;
    final velocityX =
        (_minVelocity + random.nextDouble() * (_maxVelocity - _minVelocity)) *
            (random.nextBool() ? 1 : -1);
    final velocityY =
        (_minVelocity + random.nextDouble() * (_maxVelocity - _minVelocity)) *
            (random.nextBool() ? 1 : -1);

    return _world.createEntity({
      PositionComponent(x: x, y: y),
      VelocityComponent(x: velocityX, y: velocityY),
      BoundsComponent(
        width: boundsWidth,
        height: boundsHeight,
        size: spriteSize,
      ),
      content,
      spriteRect,
    });
  }

  void update({Duration delta = const Duration(milliseconds: 16)}) {
    _world.process(delta: delta);
  }

  PositionComponent? getPosition(Entity entity) {
    return _world.getComponent<PositionComponent>(entity);
  }

  RiveContentComponent? getRiveContent(Entity entity) {
    return _world.getComponent<RiveContentComponent>(entity);
  }

  GifContentComponent? getGifContent(Entity entity) {
    return _world.getComponent<GifContentComponent>(entity);
  }

  GifAnimationStateComponent? getGifAnimationState(Entity entity) {
    return _world.getComponent<GifAnimationStateComponent>(entity);
  }

  SpriteShaderContentComponent? getSpriteShaderContent(Entity entity) {
    return _world.getComponent<SpriteShaderContentComponent>(entity);
  }

  SpriteRectComponent? getSpriteRect(Entity entity) {
    return _world.getComponent<SpriteRectComponent>(entity);
  }

  List<Entity> getEntitiesWithRiveContent() {
    final view = _world.viewForTypes({RiveContentComponent});
    return view.toList();
  }

  List<Entity> getEntitiesWithGifContent() {
    final view = _world.viewForTypes({GifContentComponent});
    return view.toList();
  }

  List<Entity> getEntitiesWithSpriteShaderContent() {
    final view = _world.viewForTypes({SpriteShaderContentComponent});
    return view.toList();
  }

  void destroyEntity(Entity entity) {
    _world.destroyEntity(entity);
  }

  void clear() {
    final riveEntities = getEntitiesWithRiveContent();
    final gifEntities = getEntitiesWithGifContent();
    final spriteShaderEntities = getEntitiesWithSpriteShaderContent();

    for (final entity in riveEntities) {
      final riveContent = _world.getComponent<RiveContentComponent>(entity);
      riveContent?.dispose();
      _world.destroyEntity(entity);
    }

    for (final entity in gifEntities) {
      _world.destroyEntity(entity);
    }

    for (final entity in spriteShaderEntities) {
      _world.destroyEntity(entity);
    }
  }

  void dispose() {
    clear();
  }
}
