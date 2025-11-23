import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:benchmark/ecs/benchmark_world.dart';
import 'package:benchmark/ecs/components/sprite_rect_component.dart';
import 'package:benchmark/ecs/components/sprite_shader_content_component.dart';
import 'package:benchmark/services/fps_tracker.dart';
import 'package:benchmark/widgets/checkerboard_background.dart';
import 'package:dentity/dentity.dart';
import 'package:flutter/material.dart';
import 'package:megasprite/megasprite.dart';

class RenderAtlasRenderer extends StatefulWidget {
  const RenderAtlasRenderer({
    required this.instanceCount,
    required this.world,
    required this.atlas,
    required this.fpsTracker,
    required this.spriteSize,
    this.spriteRects,
    super.key,
  });

  final int instanceCount;
  final BenchmarkWorld world;
  final SpriteAtlas? atlas;
  final FpsTracker fpsTracker;
  final int spriteSize;
  final List<Rect>? spriteRects;

  @override
  State<RenderAtlasRenderer> createState() => _RenderAtlasRendererState();
}

class _RenderAtlasRendererState extends State<RenderAtlasRenderer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final List<Entity> _entities = [];
  Size _lastSize = Size.zero;
  late final Stopwatch _stopwatch;
  int _lastElapsedMicroseconds = 0;

  Float32List _transforms = Float32List(0);
  Float32List _rects = Float32List(0);

  static const Duration _kFrameDuration = Duration(milliseconds: 16);

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _animationController = AnimationController(
      vsync: this,
      duration: _kFrameDuration,
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
  void didUpdateWidget(RenderAtlasRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instanceCount != widget.instanceCount ||
        oldWidget.spriteSize != widget.spriteSize ||
        oldWidget.atlas != widget.atlas) {
      _generateParticles();
    }
  }

  void _updateWorld() {
    if (_entities.isEmpty) return;

    final deltaSeconds = _getDeltaTime();
    final deltaMicroseconds = (deltaSeconds * 1000000).round();
    final delta = Duration(microseconds: deltaMicroseconds);

    widget.fpsTracker.recordFrame(deltaSeconds);
    widget.world.update(delta: delta);
  }

  void _ensureBuffers(int count) {
    if (_transforms.length != count * 4) {
      _transforms = Float32List(count * 4);
      _rects = Float32List(count * 4);
    }
  }

  void _generateParticles() {
    for (final entity in _entities) {
      widget.world.destroyEntity(entity);
    }
    _entities.clear();

    if (_lastSize.width <= 0 || _lastSize.height <= 0) {
      return;
    }

    final atlas = widget.atlas;
    if (atlas == null) return;

    final spriteRects = widget.spriteRects;
    final random = Random();

    final content = SpriteShaderContentComponent(
      image: atlas.image,
      shader: atlas.shader,
    );

    for (var i = 0; i < widget.instanceCount; i++) {
      final Rect sourceRect;
      if (spriteRects != null && spriteRects.isNotEmpty) {
        sourceRect = spriteRects[random.nextInt(spriteRects.length)];
      } else {
        final imageWidth = atlas.image.width.toDouble();
        final imageHeight = atlas.image.height.toDouble();
        sourceRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
      }

      final entity = widget.world.createSpriteShaderEntity(
        content: content,
        spriteRect: SpriteRectComponent(sourceRect: sourceRect),
        boundsWidth: _lastSize.width,
        boundsHeight: _lastSize.height,
        spriteSize: widget.spriteSize.toDouble(),
      );
      _entities.add(entity);
    }

    _ensureBuffers(_entities.length);

    if (mounted) {
      setState(() {});
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

        if (_entities.isEmpty || widget.atlas == null) {
          return const Center(
            child: Text(
              'No image file loaded',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          );
        }

        return Stack(
          children: [
            const CheckerboardBackground(),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                _updateWorld();
                return CustomPaint(
                  painter: _RenderAtlasPainter(
                    world: widget.world,
                    entities: _entities,
                    image: widget.atlas!.image,
                    spriteSize: widget.spriteSize.toDouble(),
                    transforms: _transforms,
                    rects: _rects,
                  ),
                  child: Container(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _RenderAtlasPainter extends CustomPainter {
  _RenderAtlasPainter({
    required this.world,
    required this.entities,
    required this.image,
    required this.spriteSize,
    required this.transforms,
    required this.rects,
  });

  final BenchmarkWorld world;
  final List<Entity> entities;
  final ui.Image image;
  final double spriteSize;
  final Float32List transforms;
  final Float32List rects;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    var tIndex = 0;
    var rIndex = 0;

    for (final entity in entities) {
      final position = world.getPosition(entity);
      final spriteRect = world.getSpriteRect(entity);

      if (position == null || spriteRect == null) continue;

      final scale = spriteSize / spriteRect.sourceRect.width;
      final scaledWidth = spriteSize;
      final scaledHeight = scale * spriteRect.sourceRect.height;

      final tx = position.x - scaledWidth / 2;
      final ty = position.y - scaledHeight / 2;

      // RSTransform(scos, ssin, tx, ty)
      // scos = scale * cos(0) = scale
      // ssin = scale * sin(0) = 0
      transforms[tIndex++] = scale;
      transforms[tIndex++] = 0;
      transforms[tIndex++] = tx;
      transforms[tIndex++] = ty;

      // Rect(left, top, right, bottom)
      final src = spriteRect.sourceRect;
      rects[rIndex++] = src.left;
      rects[rIndex++] = src.top;
      rects[rIndex++] = src.right;
      rects[rIndex++] = src.bottom;
    }

    canvas.drawRawAtlas(
      image,
      transforms,
      rects,
      null,
      null,
      null,
      _paint,
    );
  }

  @override
  bool shouldRepaint(_RenderAtlasPainter oldDelegate) => true;
}
