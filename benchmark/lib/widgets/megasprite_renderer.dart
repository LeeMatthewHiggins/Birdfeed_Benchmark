import 'dart:math';
import 'dart:ui' as ui;

import 'package:benchmark/ecs/benchmark_world.dart';
import 'package:benchmark/ecs/components/sprite_rect_component.dart';
import 'package:benchmark/ecs/components/sprite_shader_content_component.dart';
import 'package:benchmark/services/fps_tracker.dart';
import 'package:benchmark/widgets/checkerboard_background.dart';
import 'package:benchmark/widgets/sprite_debug_overlay.dart';
import 'package:dentity/dentity.dart';
import 'package:flutter/material.dart';
import 'package:megasprite/megasprite.dart';

class MegaSpriteRenderer extends StatefulWidget {
  const MegaSpriteRenderer({
    required this.instanceCount,
    required this.world,
    required this.atlas,
    required this.fpsTracker,
    required this.spriteSize,
    this.shader,
    this.cellSize = 32,
    this.showDebugOverlay = false,
    this.painterType = MegaSpritePainterType.shader,
    this.spriteRects,
    super.key,
  });

  final int instanceCount;
  final BenchmarkWorld world;
  final SpriteAtlas? atlas;
  final ui.FragmentShader? shader;
  final FpsTracker fpsTracker;
  final int cellSize;
  final bool showDebugOverlay;
  final int spriteSize;
  final MegaSpritePainterType painterType;
  final List<Rect>? spriteRects;

  @override
  State<MegaSpriteRenderer> createState() => _MegaSpriteRendererState();
}

class _MegaSpriteRendererState extends State<MegaSpriteRenderer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final List<Entity> _entities = [];
  Size _lastSize = Size.zero;
  late final Stopwatch _stopwatch;
  int _lastElapsedMicroseconds = 0;
  SpriteMetrics? _debugMetrics;
  final List<Sprite> _sprites = [];
  CustomPainter? _painter;
  int? _lastSpriteSize;

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
  void didUpdateWidget(MegaSpriteRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instanceCount != widget.instanceCount ||
        oldWidget.cellSize != widget.cellSize ||
        oldWidget.spriteSize != widget.spriteSize ||
        oldWidget.atlas != widget.atlas) {
      _debugMetrics = null;
      _disposePainter();
      _generateParticles();
    }
  }

  void _disposePainter() {
    final painter = _painter;
    if (painter is MegaSpriteAtlasPainter) {
      painter.dispose();
    }
    _painter = null;
  }

  void _updateSprites() {
    if (_entities.isEmpty) return;

    final deltaSeconds = _getDeltaTime();
    final deltaMicroseconds = (deltaSeconds * 1000000).round();
    final delta = Duration(microseconds: deltaMicroseconds);

    widget.fpsTracker.recordFrame(deltaSeconds);
    widget.world.update(delta: delta);

    _sprites.clear();
    for (final entity in _entities) {
      final position = widget.world.getPosition(entity);
      final spriteRect = widget.world.getSpriteRect(entity);

      if (position == null || spriteRect == null) continue;

      final spriteSize = widget.spriteSize.toDouble();
      final left = position.x - spriteSize / 2;
      final top = position.y - spriteSize / 2;

      final sprite = Sprite(
        rect: Rect.fromLTWH(
          left,
          top,
          spriteSize,
          spriteSize,
        ),
        sourceRect: spriteRect.sourceRect,
      );
      _sprites.add(sprite);
    }
  }

  CustomPainter? _getPainter() {
    if (widget.atlas == null || _entities.isEmpty) return null;

    if (_lastSpriteSize != widget.spriteSize) {
      _painter = null;
      _lastSpriteSize = widget.spriteSize;
    }

    if (widget.painterType == MegaSpritePainterType.shader) {
      final shader = widget.shader;
      if (shader == null) return null;

      return _painter ??= MegaSpriteShaderPainter(
        sprites: _sprites,
        atlas: widget.atlas!,
        shader: shader,
        cellSize: widget.cellSize,
        onBeforePaint: _updateSprites,
        onMetricsUpdate: (metrics) {
          if (!widget.showDebugOverlay) return;

          if (_debugMetrics == null) {
            _debugMetrics = metrics;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          } else {
            _debugMetrics = metrics;
          }
        },
        repaint: _animationController,
      );
    } else {
      return _painter ??= MegaSpriteAtlasPainter(
        sprites: _sprites,
        atlas: widget.atlas!,
        onBeforePaint: _updateSprites,
        repaint: _animationController,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _disposePainter();
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

    final atlas = widget.atlas;
    if (atlas == null) return;

    final spriteRects = widget.spriteRects;
    final random = Random();

    final shader = widget.shader;
    if (shader == null) return;

    final content = SpriteShaderContentComponent(
      image: atlas.image,
      shader: shader,
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

    if (widget.painterType == MegaSpritePainterType.atlas) {
      _updateSprites();
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
            RepaintBoundary(
              child: CustomPaint(
                painter: _getPainter(),
                child: Container(),
              ),
            ),
            if (widget.showDebugOverlay && _debugMetrics != null)
              SpriteDebugOverlay(
                metrics: _debugMetrics!,
                cellSize: widget.cellSize,
              ),
          ],
        );
      },
    );
  }
}
