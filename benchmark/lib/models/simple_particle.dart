import 'dart:math';

class SimpleParticle<T> {
  SimpleParticle({
    required this.content,
    required double x,
    required double y,
    required double velocityX,
    required double velocityY,
  })  : position = ParticlePosition(x, y),
        velocity = ParticleVelocity(velocityX, velocityY);

  final T content;
  final ParticlePosition position;
  final ParticleVelocity velocity;

  void updatePosition(
    double deltaSeconds,
    double boundsWidth,
    double boundsHeight,
    double instanceSize,
  ) {
    position.x += velocity.x * deltaSeconds;
    position.y += velocity.y * deltaSeconds;

    final halfSize = instanceSize / 2;

    if (position.x - halfSize <= 0) {
      position.x = halfSize;
      velocity.x = velocity.x.abs();
    } else if (position.x + halfSize >= boundsWidth) {
      position.x = boundsWidth - halfSize;
      velocity.x = -velocity.x.abs();
    }

    if (position.y - halfSize <= 0) {
      position.y = halfSize;
      velocity.y = velocity.y.abs();
    } else if (position.y + halfSize >= boundsHeight) {
      position.y = boundsHeight - halfSize;
      velocity.y = -velocity.y.abs();
    }
  }

  static SimpleParticle<T> createRandom<T>({
    required T content,
    required double boundsWidth,
    required double boundsHeight,
    double minVelocity = 50,
    double maxVelocity = 200,
  }) {
    final random = Random();
    final x = random.nextDouble() * boundsWidth;
    final y = random.nextDouble() * boundsHeight;
    final velocityX =
        (minVelocity + random.nextDouble() * (maxVelocity - minVelocity)) *
            (random.nextBool() ? 1 : -1);
    final velocityY =
        (minVelocity + random.nextDouble() * (maxVelocity - minVelocity)) *
            (random.nextBool() ? 1 : -1);

    return SimpleParticle(
      content: content,
      x: x,
      y: y,
      velocityX: velocityX,
      velocityY: velocityY,
    );
  }
}

class ParticlePosition {
  ParticlePosition(this.x, this.y);
  double x;
  double y;
}

class ParticleVelocity {
  ParticleVelocity(this.x, this.y);
  double x;
  double y;
}
