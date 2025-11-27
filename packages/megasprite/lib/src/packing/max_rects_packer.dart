import 'dart:math' as math;

import 'package:megasprite/src/models/packed_sprite.dart';
import 'package:megasprite/src/models/sprite_frame.dart';
import 'package:megasprite/src/packing/free_rect.dart';
import 'package:megasprite/src/packing/packing_strategy.dart';

class MaxRectsPacker implements PackingStrategy {
  List<FreeRect> _freeRects = [];

  @override
  void reset() {
    _freeRects = [];
  }

  @override
  PackingResult pack({
    required List<SpriteFrame> sprites,
    required int atlasWidth,
    required int atlasHeight,
    required int padding,
    required bool allowRotation,
    required int pageIndex,
  }) {
    _freeRects = [
      FreeRect(x: 0, y: 0, width: atlasWidth, height: atlasHeight),
    ];

    final sortedSprites = List<SpriteFrame>.from(sprites)
      ..sort((a, b) {
        final aMax = math.max(a.width, a.height);
        final bMax = math.max(b.width, b.height);
        return bMax.compareTo(aMax);
      });

    final packed = <PackedSprite>[];
    final overflow = <SpriteFrame>[];
    var maxX = 0;
    var maxY = 0;

    for (final sprite in sortedSprites) {
      if (sprite.isEmpty) {
        packed.add(
          PackedSprite(
            frame: sprite,
            x: 0,
            y: 0,
            rotated: false,
            pageIndex: pageIndex,
          ),
        );
        continue;
      }

      final paddedWidth = sprite.width + padding;
      final paddedHeight = sprite.height + padding;

      final placement = _findBestPosition(
        paddedWidth,
        paddedHeight,
        allowRotation,
      );

      if (placement == null) {
        overflow.add(sprite);
        continue;
      }

      final placedRect = FreeRect(
        x: placement.x,
        y: placement.y,
        width: placement.rotated ? paddedHeight : paddedWidth,
        height: placement.rotated ? paddedWidth : paddedHeight,
      );

      _splitFreeRects(placedRect);
      _pruneFreeRects();

      packed.add(
        PackedSprite(
          frame: sprite,
          x: placement.x,
          y: placement.y,
          rotated: placement.rotated,
          pageIndex: pageIndex,
        ),
      );

      maxX = math.max(maxX, placedRect.right);
      maxY = math.max(maxY, placedRect.bottom);
    }

    return PackingResult(
      packed: packed,
      overflow: overflow,
      usedWidth: maxX,
      usedHeight: maxY,
    );
  }

  _Placement? _findBestPosition(
    int width,
    int height,
    bool allowRotation,
  ) {
    _Placement? bestPlacement;
    var bestScore = _maxInt;

    for (final freeRect in _freeRects) {
      if (freeRect.canFit(width, height)) {
        final score = _calculateBssfScore(freeRect, width, height);
        if (score < bestScore) {
          bestScore = score;
          bestPlacement = _Placement(
            x: freeRect.x,
            y: freeRect.y,
            rotated: false,
          );
        }
      }

      if (allowRotation && width != height && freeRect.canFit(height, width)) {
        final score = _calculateBssfScore(freeRect, height, width);
        if (score < bestScore) {
          bestScore = score;
          bestPlacement = _Placement(
            x: freeRect.x,
            y: freeRect.y,
            rotated: true,
          );
        }
      }
    }

    return bestPlacement;
  }

  int _calculateBssfScore(FreeRect freeRect, int width, int height) {
    final leftoverHorizontal = freeRect.width - width;
    final leftoverVertical = freeRect.height - height;
    return math.min(leftoverHorizontal, leftoverVertical);
  }

  void _splitFreeRects(FreeRect placed) {
    final newFreeRects = <FreeRect>[];

    for (final freeRect in _freeRects) {
      if (!freeRect.intersects(placed)) {
        newFreeRects.add(freeRect);
        continue;
      }

      newFreeRects.addAll(freeRect.splitBy(placed));
    }

    _freeRects = newFreeRects.where((rect) {
      return !rect.intersects(placed) ||
          (rect.x >= placed.right ||
              rect.right <= placed.x ||
              rect.y >= placed.bottom ||
              rect.bottom <= placed.y);
    }).toList();
  }

  void _pruneFreeRects() {
    final pruned = <FreeRect>[];

    for (var i = 0; i < _freeRects.length; i++) {
      var isContained = false;

      for (var j = 0; j < _freeRects.length; j++) {
        if (i != j && _freeRects[j].contains(_freeRects[i])) {
          isContained = true;
          break;
        }
      }

      if (!isContained) {
        pruned.add(_freeRects[i]);
      }
    }

    _freeRects = pruned;
  }

  static const _maxInt = 0x7FFFFFFF;
}

class _Placement {
  const _Placement({
    required this.x,
    required this.y,
    required this.rotated,
  });

  final int x;
  final int y;
  final bool rotated;
}
