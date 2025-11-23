import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:megasprite/src/cell_binner.dart';
import 'package:megasprite/src/sprite.dart';
import 'package:megasprite/src/sprite_atlas.dart';
import 'package:megasprite/src/sprite_data.dart';
import 'package:megasprite/src/sprite_metrics.dart';
import 'package:megasprite/src/texture_buffer.dart';
import 'package:megasprite/src/texture_encoder.dart';
import 'package:megasprite/src/texture_layout.dart';

class MegaSpriteShaderPainter extends CustomPainter {
  MegaSpriteShaderPainter({
    required this.sprites,
    required this.atlas,
    required this.shader,
    required this.cellSize,
    this.onBeforePaint,
    this.onMetricsUpdate,
    super.repaint,
  });

  final List<Sprite> sprites;
  final SpriteAtlas atlas;
  final ui.FragmentShader shader;
  final int cellSize;
  final void Function()? onBeforePaint;
  final void Function(SpriteMetrics)? onMetricsUpdate;

  final _positionBuffer = TextureBuffer();
  final _cellCountBuffer = TextureBuffer();

  bool _isCreatingTexture = false;
  int _maxGridColumns = 0;
  int _maxGridRows = 0;
  int _maxTotalCells = 0;
  SpriteTextureLayout? _layout;
  SpriteTextureEncoder? _encoder;
  SpriteCellBinner? _binner;
  List<int>? _actualCounts;
  List<SpriteData?>? _spriteDataList;
  final _paint = Paint();
  Size _lastSize = Size.zero;
  int _cachedGridColumns = 0;
  int _cachedGridRows = 0;

  @override
  void paint(Canvas canvas, Size size) {
    onBeforePaint?.call();

    if (sprites.isEmpty) {
      return;
    }

    final currentPosTexture = _positionBuffer.current;
    final currentCountTexture = _cellCountBuffer.current;

    if (!_isCreatingTexture) {
      _createTextures(size);
    }

    if (currentPosTexture == null ||
        currentCountTexture == null ||
        _layout == null) {
      return;
    }

    if (size != _lastSize) {
      _lastSize = size;
      _cachedGridColumns = (size.width / cellSize).ceil();
      _cachedGridRows = (size.height / cellSize).ceil();
    }

    final shaderInstance = shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, _cachedGridColumns.toDouble())
      ..setFloat(3, _cachedGridRows.toDouble())
      ..setFloat(4, atlas.image.width.toDouble())
      ..setFloat(5, atlas.image.height.toDouble())
      ..setFloat(6, _layout!.dataTextureWidth.toDouble())
      ..setFloat(7, _layout!.dataTextureHeight.toDouble())
      ..setFloat(8, _layout!.cellDataWidth.toDouble())
      ..setFloat(9, cellSize.toDouble())
      ..setImageSampler(0, atlas.image)
      ..setImageSampler(1, currentPosTexture)
      ..setImageSampler(2, currentCountTexture);

    _paint.shader = shaderInstance;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _paint,
    );
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
      _positionBuffer.clear();
      _cellCountBuffer.clear();
      _binner = null;
      _actualCounts = null;
    }

    if (_binner == null ||
        _binner!.gridColumns != gridColumns ||
        _binner!.gridRows != gridRows) {
      _binner = SpriteCellBinner(
        canvasWidth: canvasSize.width,
        canvasHeight: canvasSize.height,
        spriteCount: sprites.length,
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

    if (_spriteDataList == null || _spriteDataList!.length != sprites.length) {
      _spriteDataList = List<SpriteData?>.filled(sprites.length, null);
    } else {
      _spriteDataList!.fillRange(0, sprites.length, null);
    }

    final binner = _binner!;
    final spriteDataList = _spriteDataList!;
    final actualCounts = _actualCounts!;

    for (var i = 0; i < sprites.length; i++) {
      final sprite = sprites[i];

      if (sprite.rect.width <= 0 || sprite.rect.height <= 0) {
        continue;
      }

      binner.binSprite(
        spriteIndex: i,
        rect: sprite.rect,
      );

      spriteDataList[i] = SpriteData(
        x: sprite.rect.left,
        y: sprite.rect.top,
        width: sprite.rect.width,
        height: sprite.rect.height,
        atlasX: sprite.sourceRect.left,
        atlasY: sprite.sourceRect.top,
        atlasWidth: sprite.sourceRect.width,
        atlasHeight: sprite.sourceRect.height,
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

    final positionPixels =
        _encoder!.encodePositionData(spriteDataList, actualCounts);
    final cellCountPixels = _encoder!.encodeCellCountData(actualCounts);

    final totalSprites = actualCounts.reduce((a, b) => a + b);
    final avgSprites = totalSprites / actualCounts.length;
    final maxSprites = actualCounts.reduce((a, b) => a > b ? a : b);

    onMetricsUpdate?.call(
      SpriteMetrics(
        avgSpritesPerCell: avgSprites,
        maxSpritesPerCell: maxSprites,
        positionTextureWidth: layout.dataTextureWidth,
        positionTextureHeight: layout.dataTextureHeight,
        gridColumns: _maxGridColumns,
        gridRows: _maxGridRows,
        cellCounts: actualCounts,
      ),
    );

    Future.wait([
      _positionBuffer.update(
        positionPixels,
        layout.dataTextureWidth,
        layout.dataTextureHeight,
      ),
      _cellCountBuffer.update(
        cellCountPixels,
        _maxGridColumns,
        _maxGridRows,
      ),
    ]).then((_) {
      _isCreatingTexture = false;
    }).catchError((Object error, StackTrace stackTrace) {
      _isCreatingTexture = false;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  void dispose() {
    _positionBuffer.dispose();
    _cellCountBuffer.dispose();
    _paint.shader = null;
  }

  @override
  bool shouldRepaint(MegaSpriteShaderPainter oldDelegate) =>
      oldDelegate.sprites != sprites ||
      oldDelegate.cellSize != cellSize ||
      oldDelegate.atlas != atlas ||
      oldDelegate.shader != shader;
}
