import 'package:flutter/material.dart';
import 'package:benchmark/ecs/benchmark_world.dart';
import 'package:benchmark/ecs/components/gif_content_component.dart';
import 'package:benchmark/services/fps_tracker.dart';
import 'package:benchmark/widgets/checkerboard_background.dart';
import 'package:dentity/dentity.dart';

class GifParticleRenderer extends StatefulWidget {
  const GifParticleRenderer({
    required this.instanceCount,
    required this.world,
    required this.createGifContent,
    required this.fpsTracker,
    super.key,
  });

  final int instanceCount;
  final BenchmarkWorld world;
  final GifContentComponent? Function() createGifContent;
  final FpsTracker fpsTracker;

  @override
  State<GifParticleRenderer> createState() => _GifParticleRendererState();
}

class _GifParticleRendererState extends State<GifParticleRenderer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final List<Entity> _entities = [];
  Size _lastSize = Size.zero;
  late final Stopwatch _stopwatch;
  int _lastElapsedMicroseconds = 0;

  static const Duration _frameDuration = Duration(milliseconds: 16);
  static const double _instanceSize = 100;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _animationController = AnimationController(
      vsync: this,
      duration: _frameDuration,
    )..repeat();
  }

  double _getDeltaTime() {
    final currentMicroseconds = _stopwatch.elapsedMicroseconds;
    final deltaMicroseconds = currentMicroseconds - _lastElapsedMicroseconds;
    _lastElapsedMicroseconds = currentMicroseconds;

    if (deltaMicroseconds == 0) {
      return 0.016;
    }

    return (deltaMicroseconds / 1000000.0).clamp(0.0, 0.1);
  }

  @override
  void didUpdateWidget(GifParticleRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instanceCount != widget.instanceCount) {
      _generateParticles();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final entity in _entities) {
      widget.world.destroyEntity(entity);
    }
    _entities.clear();
    super.dispose();
  }

  void _generateParticles() {
    for (final entity in _entities) {
      widget.world.destroyEntity(entity);
    }
    _entities.clear();

    if (_lastSize.width <= 0 || _lastSize.height <= 0) {
      return;
    }

    final sharedContent = widget.createGifContent();
    if (sharedContent == null) return;

    for (var i = 0; i < widget.instanceCount; i++) {
      final entity = widget.world.createGifEntity(
        content: sharedContent,
        boundsWidth: _lastSize.width,
        boundsHeight: _lastSize.height,
      );
      _entities.add(entity);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final newSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (_lastSize != newSize) {
          _lastSize = newSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _generateParticles();
          });
        }

        if (_entities.isEmpty) {
          return const Center(
            child: Text(
              'No GIF file loaded',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          );
        }

        return Stack(
          children: [
            const CheckerboardBackground(),
            RepaintBoundary(
              child: CustomPaint(
                painter: _GifParticlePainter(
                  world: widget.world,
                  entities: _entities,
                  instanceSize: _instanceSize,
                  getDeltaTime: _getDeltaTime,
                  fpsTracker: widget.fpsTracker,
                  repaint: _animationController,
                ),
                child: Container(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GifParticlePainter extends CustomPainter {
  _GifParticlePainter({
    required this.world,
    required this.entities,
    required this.instanceSize,
    required this.getDeltaTime,
    required this.fpsTracker,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final BenchmarkWorld world;
  final List<Entity> entities;
  final double instanceSize;
  final double Function() getDeltaTime;
  final FpsTracker fpsTracker;

  @override
  void paint(Canvas canvas, Size size) {
    if (entities.isEmpty) {
      return;
    }

    final deltaSeconds = getDeltaTime();
    final deltaMicroseconds = (deltaSeconds * 1000000).round();
    final delta = Duration(microseconds: deltaMicroseconds);

    fpsTracker.recordFrame(deltaSeconds);

    world.update(delta: delta);

    final paint = Paint();

    for (final entity in entities) {
      final position = world.getPosition(entity);
      final content = world.getGifContent(entity);
      final animState = world.getGifAnimationState(entity);

      if (position == null || content == null || animState == null) continue;

      final x = position.x;
      final y = position.y;
      final currentFrame = content.frames[animState.currentFrameIndex];

      final srcWidth = currentFrame.width.toDouble();
      final srcHeight = currentFrame.height.toDouble();
      final scale = instanceSize / srcWidth;

      canvas
        ..save()
        ..translate(x, y)
        ..scale(scale, scale)
        ..translate(-srcWidth / 2, -srcHeight / 2)
        ..drawImage(currentFrame, Offset.zero, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_GifParticlePainter oldDelegate) => true;
}
