import 'dart:ui' as ui;

import 'package:benchmark/ecs/benchmark_world.dart';
import 'package:benchmark/ecs/components/sprite_rect_component.dart';
import 'package:benchmark/ecs/components/sprite_shader_content_component.dart';
import 'package:benchmark/services/fps_tracker.dart';
import 'package:benchmark/widgets/checkerboard_background.dart';
import 'package:benchmark/widgets/sprite_cell_binner.dart';
import 'package:benchmark/widgets/sprite_debug_overlay.dart';
import 'package:benchmark/widgets/sprite_texture_encoder.dart';
import 'package:benchmark/widgets/sprite_texture_layout.dart';
import 'package:dentity/dentity.dart';
import 'package:flutter/material.dart';

class SpriteShaderRenderer extends StatefulWidget {
  const SpriteShaderRenderer({
    required this.instanceCount,
    required this.world,
    required this.createSpriteShaderContent,
    required this.fpsTracker,
    required this.cellSize,
    required this.showDebugOverlay,
    required this.spriteSize,
    super.key,
  });

  final int instanceCount;
  final BenchmarkWorld world;
  final SpriteShaderContentComponent? Function() createSpriteShaderContent;
  final FpsTracker fpsTracker;
  final int cellSize;
  final bool showDebugOverlay;
  final int spriteSize;

  @override
  State<SpriteShaderRenderer> createState() => _SpriteShaderRendererState();
}

class _SpriteShaderRendererState extends State<SpriteShaderRenderer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final List<Entity> _entities = [];
  Size _lastSize = Size.zero;
  late final Stopwatch _stopwatch;
  int _lastElapsedMicroseconds = 0;
  SpriteDebugMetrics? _debugMetrics;

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
  void didUpdateWidget(SpriteShaderRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instanceCount != widget.instanceCount ||
        oldWidget.cellSize != widget.cellSize ||
        oldWidget.spriteSize != widget.spriteSize) {
      _debugMetrics = null;
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

    final sharedContent = widget.createSpriteShaderContent();
    if (sharedContent == null) return;

    final imageWidth = sharedContent.image.width.toDouble();
    final imageHeight = sharedContent.image.height.toDouble();
    final sourceRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);

    for (var i = 0; i < widget.instanceCount; i++) {
      final entity = widget.world.createSpriteShaderEntity(
        content: sharedContent,
        spriteRect: SpriteRectComponent(sourceRect: sourceRect),
        boundsWidth: _lastSize.width,
        boundsHeight: _lastSize.height,
        spriteSize: widget.spriteSize.toDouble(),
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
                painter: _SpriteShaderPainter(
                  world: widget.world,
                  entities: _entities,
                  instanceSize: widget.spriteSize.toDouble(),
                  getDeltaTime: _getDeltaTime,
                  fpsTracker: widget.fpsTracker,
                  canvasSize: _lastSize,
                  cellSize: widget.cellSize,
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
                ),
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

class _SpriteShaderPainter extends CustomPainter {
  _SpriteShaderPainter({
    required this.world,
    required this.entities,
    required this.instanceSize,
    required this.getDeltaTime,
    required this.fpsTracker,
    required this.canvasSize,
    required this.cellSize,
    required this.onMetricsUpdate,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final BenchmarkWorld world;
  final List<Entity> entities;
  final double instanceSize;
  final double Function() getDeltaTime;
  final FpsTracker fpsTracker;
  final Size canvasSize;
  final int cellSize;
  final void Function(SpriteDebugMetrics) onMetricsUpdate;

  ui.Image? _positionTextureA;
  ui.Image? _positionTextureB;
  ui.Image? _cellCountTextureA;
  ui.Image? _cellCountTextureB;
  bool _useTextureA = true;
  bool _isCreatingTexture = false;
  int _maxGridColumns = 0;
  int _maxGridRows = 0;
  int _maxTotalCells = 0;
  SpriteTextureLayout? _layout;
  SpriteTextureEncoder? _encoder;
  SpriteCellBinner? _binner;
  List<int>? _actualCounts;
  List<SpriteData?>? _spriteDataList;

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

    final firstEntity = entities.first;
    final content = world.getSpriteShaderContent(firstEntity);
    if (content == null) return;

    final currentPosTexture =
        _useTextureA ? _positionTextureA : _positionTextureB;
    final currentCountTexture =
        _useTextureA ? _cellCountTextureA : _cellCountTextureB;

    if (!_isCreatingTexture) {
      _createTextures(size);
    }

    if (currentPosTexture == null || currentCountTexture == null || _layout == null) return;

    final gridColumns = (size.width / cellSize).ceil();
    final gridRows = (size.height / cellSize).ceil();

    final shader = content.shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, gridColumns.toDouble())
      ..setFloat(3, gridRows.toDouble())
      ..setFloat(4, instanceSize)
      ..setFloat(5, content.image.width.toDouble())
      ..setFloat(6, content.image.height.toDouble())
      ..setFloat(7, _layout!.textureWidth.toDouble())
      ..setFloat(8, _layout!.textureHeight.toDouble())
      ..setFloat(9, _layout!.cellsPerRow.toDouble())
      ..setFloat(10, _layout!.cellDataWidth.toDouble())
      ..setFloat(11, cellSize.toDouble())
      ..setImageSampler(0, content.image)
      ..setImageSampler(1, currentPosTexture)
      ..setImageSampler(2, currentCountTexture);

    final paint = Paint()..shader = shader;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  void _swapTextures(ui.Image positionTexture, ui.Image cellCountTexture) {
    if (_useTextureA) {
      _positionTextureB = positionTexture;
      _cellCountTextureB = cellCountTexture;
    } else {
      _positionTextureA = positionTexture;
      _cellCountTextureA = cellCountTexture;
    }
    _useTextureA = !_useTextureA;
    _isCreatingTexture = false;
  }

  void _createTextures(Size canvasSize) {
    _isCreatingTexture = true;

    final gridColumns = (canvasSize.width / cellSize).ceil();
    final gridRows = (canvasSize.height / cellSize).ceil();
    final totalCells = gridColumns * gridRows;

    if (_maxTotalCells != totalCells) {
      _maxGridColumns = gridColumns;
      _maxGridRows = gridRows;
      _maxTotalCells = totalCells;
      _layout = SpriteTextureLayout(totalCells: totalCells);
      _positionTextureA?.dispose();
      _positionTextureB?.dispose();
      _cellCountTextureA?.dispose();
      _cellCountTextureB?.dispose();
      _positionTextureA = null;
      _positionTextureB = null;
      _cellCountTextureA = null;
      _cellCountTextureB = null;
      _binner = null;
      _actualCounts = null;
    }

    if (_binner == null ||
        _binner!.gridColumns != gridColumns ||
        _binner!.gridRows != gridRows) {
      _binner = SpriteCellBinner(
        canvasWidth: canvasSize.width,
        canvasHeight: canvasSize.height,
        spriteCount: entities.length,
        cellSize: cellSize,
      );
    } else {
      _binner!.clear();
    }

    if (_actualCounts == null || _actualCounts!.length != _maxTotalCells) {
      _actualCounts = List<int>.filled(_maxTotalCells, 0);
    } else {
      _actualCounts!.fillRange(0, _maxTotalCells, 0);
    }

    if (_spriteDataList == null || _spriteDataList!.length != entities.length) {
      _spriteDataList = List<SpriteData?>.filled(entities.length, null);
    } else {
      _spriteDataList!.fillRange(0, entities.length, null);
    }

    final binner = _binner!;
    final spriteDataList = _spriteDataList!;
    final actualCounts = _actualCounts!;

    for (var i = 0; i < entities.length; i++) {
      final entity = entities[i];
      final position = world.getPosition(entity);
      final spriteRect = world.getSpriteRect(entity);
      final content = world.getSpriteShaderContent(entity);

      if (position == null || spriteRect == null || content == null) continue;

      binner.binSprite(
        spriteIndex: i,
        posX: position.x,
        posY: position.y,
        spriteSize: instanceSize,
      );

      final imageWidth = content.image.width.toDouble();
      final imageHeight = content.image.height.toDouble();

      final halfSize = instanceSize / 2;
      spriteDataList[i] = SpriteData(
        minX: position.x - halfSize,
        minY: position.y - halfSize,
        maxX: position.x + halfSize,
        maxY: position.y + halfSize,
        srcX: spriteRect.sourceRect.left / imageWidth,
        srcY: spriteRect.sourceRect.top / imageHeight,
        srcWidth: spriteRect.sourceRect.width / imageWidth,
        srcHeight: spriteRect.sourceRect.height / imageHeight,
      );
    }

    final layout = _layout!;

    if (_encoder == null ||
        _encoder!.binner.gridColumns != binner.gridColumns ||
        _encoder!.binner.gridRows != binner.gridRows) {
      _encoder = SpriteTextureEncoder(
        binner: binner,
        canvasWidth: canvasSize.width,
        canvasHeight: canvasSize.height,
        layout: layout,
        maxGridColumns: _maxGridColumns,
        maxGridRows: _maxGridRows,
      );
    }

    final positionPixels = _encoder!.encodePositionData(spriteDataList, actualCounts);
    final cellCountPixels = _encoder!.encodeCellCountData(actualCounts);

    final totalSprites = actualCounts.reduce((a, b) => a + b);
    final avgSprites = totalSprites / actualCounts.length;
    final maxSprites = actualCounts.reduce((a, b) => a > b ? a : b);

    onMetricsUpdate(
      SpriteDebugMetrics(
        avgSpritesPerCell: avgSprites,
        maxSpritesPerCell: maxSprites,
        textureWidth: layout.textureWidth,
        textureHeight: layout.textureHeight,
        gridColumns: _maxGridColumns,
        gridRows: _maxGridRows,
        cellCounts: actualCounts,
      ),
    );

    ui.Image? newPositionTexture;
    ui.Image? newCellCountTexture;

    ui.decodeImageFromPixels(
      positionPixels,
      layout.textureWidth,
      layout.textureHeight,
      ui.PixelFormat.rgba8888,
      (image) {
        newPositionTexture = image;
        if (newCellCountTexture != null) {
          _swapTextures(newPositionTexture!, newCellCountTexture!);
        }
      },
    );

    ui.decodeImageFromPixels(
      cellCountPixels,
      _maxGridColumns,
      _maxGridRows,
      ui.PixelFormat.rgba8888,
      (image) {
        newCellCountTexture = image;
        if (newPositionTexture != null) {
          _swapTextures(newPositionTexture!, newCellCountTexture!);
        }
      },
    );
  }

  @override
  bool shouldRepaint(_SpriteShaderPainter oldDelegate) => true;
}
