import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:megasprite/src/atlas/atlas_build_progress.dart';
import 'package:megasprite/src/atlas/atlas_builder.dart' show AtlasBuildException;
import 'package:megasprite/src/atlas/atlas_builder_config.dart';
import 'package:megasprite/src/atlas/atlas_page.dart';
import 'package:megasprite/src/atlas/atlas_result.dart';
import 'package:megasprite/src/atlas/image_trimmer.dart';
import 'package:megasprite/src/models/packed_sprite.dart';
import 'package:megasprite/src/models/source_sprite.dart';
import 'package:megasprite/src/models/sprite_frame.dart';
import 'package:megasprite/src/models/trim_rect.dart';
import 'package:megasprite/src/packing/free_rect.dart';

class _ProcessedSprite {
  const _ProcessedSprite({
    required this.identifier,
    required this.trimmedPixels,
    required this.trimRect,
    required this.pixelHash,
  });

  final String identifier;
  final Uint8List trimmedPixels;
  final TrimRect trimRect;
  final int pixelHash;
}

class _PackedSpriteData {
  const _PackedSpriteData({
    required this.spriteIndex,
    required this.x,
    required this.y,
    required this.rotated,
    required this.pageIndex,
  });

  final int spriteIndex;
  final int x;
  final int y;
  final bool rotated;
  final int pageIndex;
}

class _PageData {
  const _PageData({
    required this.packedSprites,
    required this.aliases,
    required this.pageIndex,
    required this.width,
    required this.height,
  });

  final List<_PackedSpriteData> packedSprites;
  final List<_AliasData> aliases;
  final int pageIndex;
  final int width;
  final int height;
}

class _AliasData {
  const _AliasData({
    required this.identifier,
    required this.targetSpriteIndex,
    required this.pageIndex,
  });

  final String identifier;
  final int targetSpriteIndex;
  final int pageIndex;
}

class _BuildResult {
  const _BuildResult({
    required this.processedSprites,
    required this.pages,
    required this.totalSpriteCount,
    required this.uniqueSpriteCount,
    required this.duplicateCount,
  });

  final List<_ProcessedSprite> processedSprites;
  final List<_PageData> pages;
  final int totalSpriteCount;
  final int uniqueSpriteCount;
  final int duplicateCount;
}

class _DecodedImage {
  const _DecodedImage({
    required this.pixels,
    required this.width,
    required this.height,
  });

  final Uint8List pixels;
  final int width;
  final int height;
}

class IsolateAtlasBuilder {
  IsolateAtlasBuilder({
    this.sizePreset = AtlasBuilderConfig.defaultSizePreset,
    this.padding = AtlasBuilderConfig.defaultPadding,
    this.allowRotation = AtlasBuilderConfig.defaultAllowRotation,
    this.trimTolerance = AtlasBuilderConfig.defaultTrimTolerance,
    this.packingAlgorithm = AtlasBuilderConfig.defaultPackingAlgorithm,
  });

  final AtlasSizePreset sizePreset;
  final int padding;
  final bool allowRotation;
  final int trimTolerance;
  final PackingAlgorithm packingAlgorithm;

  AtlasResult? _lastResult;

  Stream<AtlasBuildProgress> buildWithProgress(
    List<SourceSprite> sprites,
  ) async* {
    final total = sprites.length;

    yield AtlasBuildProgress(
      phase: AtlasBuildPhase.decoding,
      current: 0,
      total: total,
    );

    final decodedImages = <_DecodedImage>[];
    final identifiers = <String>[];

    for (var i = 0; i < sprites.length; i++) {
      final sprite = sprites[i];
      try {
        final image = await _decodeImage(sprite.imageBytes);
        final byteData = await image.toByteData();
        if (byteData != null) {
          decodedImages.add(
            _DecodedImage(
              pixels: byteData.buffer.asUint8List(),
              width: image.width,
              height: image.height,
            ),
          );
          identifiers.add(sprite.identifier);
        }
        image.dispose();
      } on Exception catch (e) {
        throw AtlasBuildException(
          'Failed to decode image "${sprite.identifier}": $e',
        );
      }

      yield AtlasBuildProgress(
        phase: AtlasBuildPhase.decoding,
        current: i + 1,
        total: total,
        message: sprite.identifier.split('/').last,
      );
    }

    yield AtlasBuildProgress(
      phase: AtlasBuildPhase.trimming,
      current: 0,
      total: total,
    );

    final processedSprites = <_ProcessedSprite>[];

    for (var i = 0; i < decodedImages.length; i++) {
      final decoded = decodedImages[i];
      final identifier = identifiers[i];

      final trimResult = _trimImage(
        decoded.pixels,
        decoded.width,
        decoded.height,
        trimTolerance,
      );

      processedSprites.add(
        _ProcessedSprite(
          identifier: identifier,
          trimmedPixels: trimResult.trimmedPixels,
          trimRect: trimResult.trimRect,
          pixelHash: trimResult.pixelHash,
        ),
      );

      yield AtlasBuildProgress(
        phase: AtlasBuildPhase.trimming,
        current: i + 1,
        total: total,
        message: identifier.split('/').last,
      );

      await _yieldToEventLoop();
    }

    yield AtlasBuildProgress(
      phase: AtlasBuildPhase.deduplicating,
      current: 0,
      total: 1,
    );

    final deduplicationResult = _deduplicateSprites(processedSprites);

    yield AtlasBuildProgress(
      phase: AtlasBuildPhase.deduplicating,
      current: 1,
      total: 1,
    );

    final packingTotal = deduplicationResult.uniqueSprites.length;

    yield AtlasBuildProgress(
      phase: AtlasBuildPhase.packing,
      current: 0,
      total: packingTotal,
    );

    final progressController = StreamController<AtlasBuildProgress>();

    unawaited(
      _packSpritesAsync(
        processedSprites,
        deduplicationResult,
        sizePreset.dimension,
        padding,
        allowRotation,
        packingAlgorithm,
        progressController,
      ),
    );

    List<_PageData>? pages;

    await for (final event in progressController.stream) {
      if (event is _PackingComplete) {
        pages = event.pages;
        break;
      }
      yield event;
    }

    if (pages == null) {
      throw AtlasBuildException('Packing failed');
    }

    final buildResult = _BuildResult(
      processedSprites: processedSprites,
      pages: pages,
      totalSpriteCount: decodedImages.length,
      uniqueSpriteCount: deduplicationResult.uniqueSprites.length,
      duplicateCount: deduplicationResult.duplicates.length,
    );

    yield AtlasBuildProgress(
      phase: AtlasBuildPhase.compositing,
      current: 0,
      total: buildResult.pages.length,
    );

    _lastResult = await _buildFinalResult(buildResult);
  }

  AtlasResult getResult() {
    if (_lastResult == null) {
      throw StateError('No result available. Call buildWithProgress first.');
    }
    return _lastResult!;
  }

  Future<AtlasResult> _buildFinalResult(_BuildResult buildResult) async {
    final spriteFrames = <SpriteFrame>[];

    for (final processed in buildResult.processedSprites) {
      ui.Image image;
      if (processed.trimRect.isEmpty) {
        image = await _createEmptyImage();
      } else {
        image = await ImageTrimmer.createImageFromPixels(
          processed.trimmedPixels,
          processed.trimRect.width,
          processed.trimRect.height,
        );
      }
      spriteFrames.add(
        SpriteFrame(
          identifier: processed.identifier,
          trimmedImage: image,
          trimRect: processed.trimRect,
          pixelHash: processed.pixelHash,
        ),
      );
    }

    final pages = <AtlasPage>[];

    for (final pageData in buildResult.pages) {
      final packedSprites = <PackedSprite>[];

      for (final packed in pageData.packedSprites) {
        packedSprites.add(
          PackedSprite(
            frame: spriteFrames[packed.spriteIndex],
            x: packed.x,
            y: packed.y,
            rotated: packed.rotated,
            pageIndex: packed.pageIndex,
          ),
        );
      }

      final aliases = <SpriteAlias>[];
      for (final alias in pageData.aliases) {
        final targetPacked = packedSprites.firstWhere(
          (p) => spriteFrames.indexOf(p.frame) == alias.targetSpriteIndex,
        );
        aliases.add(
          SpriteAlias(
            identifier: alias.identifier,
            packedSprite: targetPacked,
          ),
        );
      }

      final atlasImage = await _compositeAtlasImage(
        packedSprites,
        pageData.width,
        pageData.height,
      );

      pages.add(
        AtlasPage(
          image: atlasImage,
          packedSprites: packedSprites,
          aliases: aliases,
          pageIndex: pageData.pageIndex,
          width: pageData.width,
          height: pageData.height,
        ),
      );
    }

    return AtlasResult(
      pages: pages,
      totalSpriteCount: buildResult.totalSpriteCount,
      uniqueSpriteCount: buildResult.uniqueSpriteCount,
      duplicateCount: buildResult.duplicateCount,
    );
  }

  Future<ui.Image> _createEmptyImage() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    picture.dispose();
    return image;
  }

  Future<ui.Image> _compositeAtlasImage(
    List<PackedSprite> packed,
    int width,
    int height,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    for (final sprite in packed) {
      if (sprite.frame.isEmpty) continue;

      final image = sprite.frame.trimmedImage;

      if (sprite.rotated) {
        canvas
          ..save()
          ..translate(
            sprite.x.toDouble() + sprite.packedWidth,
            sprite.y.toDouble(),
          )
          ..rotate(3.14159265359 / 2)
          ..drawImage(image, ui.Offset.zero, ui.Paint())
          ..restore();
      } else {
        canvas.drawImage(
          image,
          ui.Offset(sprite.x.toDouble(), sprite.y.toDouble()),
          ui.Paint(),
        );
      }
    }

    final picture = recorder.endRecording();
    final atlasImage = await picture.toImage(width, height);
    picture.dispose();

    return atlasImage;
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _yieldToEventLoop() async {
    await Future<void>.delayed(Duration.zero);
  }
}

class _PackingComplete extends AtlasBuildProgress {
  _PackingComplete(this.pages)
      : super(
          phase: AtlasBuildPhase.packing,
          current: 0,
          total: 0,
        );

  final List<_PageData> pages;
}

class _TrimResult {
  const _TrimResult({
    required this.trimmedPixels,
    required this.trimRect,
    required this.pixelHash,
  });

  final Uint8List trimmedPixels;
  final TrimRect trimRect;
  final int pixelHash;
}

_TrimResult _trimImage(Uint8List pixels, int width, int height, int tolerance) {
  const bytesPerPixel = 4;
  const alphaOffset = 3;

  var minX = width;
  var maxX = -1;
  var minY = height;
  var maxY = -1;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = (y * width + x) * bytesPerPixel + alphaOffset;
      if (pixels[index] > tolerance) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX < minX || maxY < minY) {
    return _TrimResult(
      trimmedPixels: Uint8List(0),
      trimRect: TrimRect(
        originalWidth: width,
        originalHeight: height,
        x: 0,
        y: 0,
        width: 0,
        height: 0,
      ),
      pixelHash: 0,
    );
  }

  final trimWidth = maxX - minX + 1;
  final trimHeight = maxY - minY + 1;
  final trimmedPixels = Uint8List(trimWidth * trimHeight * bytesPerPixel);

  for (var y = 0; y < trimHeight; y++) {
    final srcRowStart = ((minY + y) * width + minX) * bytesPerPixel;
    final dstRowStart = y * trimWidth * bytesPerPixel;
    final rowBytes = trimWidth * bytesPerPixel;

    trimmedPixels.setRange(
      dstRowStart,
      dstRowStart + rowBytes,
      pixels,
      srcRowStart,
    );
  }

  var hash = 0;
  for (var i = 0; i < trimmedPixels.length; i++) {
    hash = (hash * 31 + trimmedPixels[i]) & 0x7FFFFFFF;
  }

  return _TrimResult(
    trimmedPixels: trimmedPixels,
    trimRect: TrimRect(
      originalWidth: width,
      originalHeight: height,
      x: minX,
      y: minY,
      width: trimWidth,
      height: trimHeight,
    ),
    pixelHash: hash,
  );
}

class _DeduplicationResult {
  const _DeduplicationResult({
    required this.uniqueSprites,
    required this.duplicates,
  });

  final List<int> uniqueSprites;
  final Map<int, int> duplicates;
}

_DeduplicationResult _deduplicateSprites(List<_ProcessedSprite> sprites) {
  final hashToIndex = <int, int>{};
  final uniqueIndices = <int>[];
  final duplicates = <int, int>{};

  for (var i = 0; i < sprites.length; i++) {
    final sprite = sprites[i];
    if (sprite.trimRect.isEmpty) {
      uniqueIndices.add(i);
      continue;
    }

    final existingIndex = hashToIndex[sprite.pixelHash];
    if (existingIndex != null) {
      duplicates[i] = existingIndex;
    } else {
      hashToIndex[sprite.pixelHash] = i;
      uniqueIndices.add(i);
    }
  }

  return _DeduplicationResult(
    uniqueSprites: uniqueIndices,
    duplicates: duplicates,
  );
}

Future<void> _packSpritesAsync(
  List<_ProcessedSprite> allSprites,
  _DeduplicationResult deduplication,
  int atlasSize,
  int padding,
  bool allowRotation,
  PackingAlgorithm algorithm,
  StreamController<AtlasBuildProgress> progressController,
) async {
  final pages = <_PageData>[];
  var remaining = List<int>.from(deduplication.uniqueSprites);
  var pageIndex = 0;
  var packedCount = 0;
  final total = deduplication.uniqueSprites.length;

  while (remaining.isNotEmpty) {
    final freeRects = <FreeRect>[
      FreeRect(x: 0, y: 0, width: atlasSize, height: atlasSize),
    ];
    final packedOnPage = <_PackedSpriteData>[];
    final notPacked = <int>[];

    final sorted = List<int>.from(remaining)
      ..sort((a, b) {
        final spriteA = allSprites[a];
        final spriteB = allSprites[b];
        final maxA =
            spriteA.trimRect.width > spriteA.trimRect.height
                ? spriteA.trimRect.width
                : spriteA.trimRect.height;
        final maxB =
            spriteB.trimRect.width > spriteB.trimRect.height
                ? spriteB.trimRect.width
                : spriteB.trimRect.height;
        return maxB.compareTo(maxA);
      });

    for (final spriteIndex in sorted) {
      final sprite = allSprites[spriteIndex];
      final spriteWidth = sprite.trimRect.width + padding * 2;
      final spriteHeight = sprite.trimRect.height + padding * 2;

      if (sprite.trimRect.isEmpty) {
        packedOnPage.add(
          _PackedSpriteData(
            spriteIndex: spriteIndex,
            x: 0,
            y: 0,
            rotated: false,
            pageIndex: pageIndex,
          ),
        );
        packedCount++;
        progressController.add(
          AtlasBuildProgress(
            phase: AtlasBuildPhase.packing,
            current: packedCount,
            total: total,
          ),
        );
        continue;
      }

      final placement = _findPlacement(
        freeRects,
        spriteWidth,
        spriteHeight,
        allowRotation,
        algorithm,
      );

      if (placement != null) {
        packedOnPage.add(
          _PackedSpriteData(
            spriteIndex: spriteIndex,
            x: placement.x + padding,
            y: placement.y + padding,
            rotated: placement.rotated,
            pageIndex: pageIndex,
          ),
        );

        _splitFreeRects(freeRects, placement);
        _pruneFreeRects(freeRects);

        packedCount++;
        progressController.add(
          AtlasBuildProgress(
            phase: AtlasBuildPhase.packing,
            current: packedCount,
            total: total,
          ),
        );

        if (packedCount % 10 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      } else {
        notPacked.add(spriteIndex);
      }
    }

    if (packedOnPage.isEmpty && notPacked.isNotEmpty) {
      final oversized = allSprites[notPacked.first];
      progressController.addError(
        AtlasBuildException(
          'Sprite "${oversized.identifier}" is too large for atlas',
        ),
      );
      await progressController.close();
      return;
    }

    final aliases = <_AliasData>[];
    for (final entry in deduplication.duplicates.entries) {
      final duplicateIndex = entry.key;
      final originalIndex = entry.value;
      final isOnThisPage =
          packedOnPage.any((p) => p.spriteIndex == originalIndex);
      if (isOnThisPage) {
        aliases.add(
          _AliasData(
            identifier: allSprites[duplicateIndex].identifier,
            targetSpriteIndex: originalIndex,
            pageIndex: pageIndex,
          ),
        );
      }
    }

    pages.add(
      _PageData(
        packedSprites: packedOnPage,
        aliases: aliases,
        pageIndex: pageIndex,
        width: atlasSize,
        height: atlasSize,
      ),
    );

    remaining = notPacked;
    pageIndex++;
  }

  progressController.add(_PackingComplete(pages));
  await progressController.close();
}

class _Placement {
  const _Placement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotated,
  });

  final int x;
  final int y;
  final int width;
  final int height;
  final bool rotated;
}

_Placement? _findPlacement(
  List<FreeRect> freeRects,
  int width,
  int height,
  bool allowRotation,
  PackingAlgorithm algorithm,
) {
  return switch (algorithm) {
    PackingAlgorithm.maxRectsBssf => _findBssfPlacement(
        freeRects,
        width,
        height,
        allowRotation,
      ),
    PackingAlgorithm.maxRectsBaf => _findBafPlacement(
        freeRects,
        width,
        height,
        allowRotation,
      ),
    PackingAlgorithm.shelf => _findShelfPlacement(
        freeRects,
        width,
        height,
        allowRotation,
      ),
  };
}

_Placement? _findBssfPlacement(
  List<FreeRect> freeRects,
  int width,
  int height,
  bool allowRotation,
) {
  _Placement? best;
  var bestShortSide = 0x7FFFFFFF;
  var bestLongSide = 0x7FFFFFFF;

  for (final rect in freeRects) {
    if (rect.width >= width && rect.height >= height) {
      final leftoverH = (rect.width - width).abs();
      final leftoverV = (rect.height - height).abs();
      final shortSide = leftoverH < leftoverV ? leftoverH : leftoverV;
      final longSide = leftoverH > leftoverV ? leftoverH : leftoverV;

      if (shortSide < bestShortSide ||
          (shortSide == bestShortSide && longSide < bestLongSide)) {
        best = _Placement(
          x: rect.x,
          y: rect.y,
          width: width,
          height: height,
          rotated: false,
        );
        bestShortSide = shortSide;
        bestLongSide = longSide;
      }
    }

    if (allowRotation && rect.width >= height && rect.height >= width) {
      final leftoverH = (rect.width - height).abs();
      final leftoverV = (rect.height - width).abs();
      final shortSide = leftoverH < leftoverV ? leftoverH : leftoverV;
      final longSide = leftoverH > leftoverV ? leftoverH : leftoverV;

      if (shortSide < bestShortSide ||
          (shortSide == bestShortSide && longSide < bestLongSide)) {
        best = _Placement(
          x: rect.x,
          y: rect.y,
          width: height,
          height: width,
          rotated: true,
        );
        bestShortSide = shortSide;
        bestLongSide = longSide;
      }
    }
  }

  return best;
}

_Placement? _findBafPlacement(
  List<FreeRect> freeRects,
  int width,
  int height,
  bool allowRotation,
) {
  _Placement? best;
  var bestAreaFit = 0x7FFFFFFF;
  var bestShortSide = 0x7FFFFFFF;

  for (final rect in freeRects) {
    if (rect.width >= width && rect.height >= height) {
      final areaFit = rect.width * rect.height - width * height;
      final leftoverH = (rect.width - width).abs();
      final leftoverV = (rect.height - height).abs();
      final shortSide = leftoverH < leftoverV ? leftoverH : leftoverV;

      if (areaFit < bestAreaFit ||
          (areaFit == bestAreaFit && shortSide < bestShortSide)) {
        best = _Placement(
          x: rect.x,
          y: rect.y,
          width: width,
          height: height,
          rotated: false,
        );
        bestAreaFit = areaFit;
        bestShortSide = shortSide;
      }
    }

    if (allowRotation && rect.width >= height && rect.height >= width) {
      final areaFit = rect.width * rect.height - width * height;
      final leftoverH = (rect.width - height).abs();
      final leftoverV = (rect.height - width).abs();
      final shortSide = leftoverH < leftoverV ? leftoverH : leftoverV;

      if (areaFit < bestAreaFit ||
          (areaFit == bestAreaFit && shortSide < bestShortSide)) {
        best = _Placement(
          x: rect.x,
          y: rect.y,
          width: height,
          height: width,
          rotated: true,
        );
        bestAreaFit = areaFit;
        bestShortSide = shortSide;
      }
    }
  }

  return best;
}

_Placement? _findShelfPlacement(
  List<FreeRect> freeRects,
  int width,
  int height,
  bool allowRotation,
) {
  _Placement? best;
  var bestY = 0x7FFFFFFF;
  var bestX = 0x7FFFFFFF;

  for (final rect in freeRects) {
    if (rect.width >= width && rect.height >= height) {
      if (rect.y < bestY || (rect.y == bestY && rect.x < bestX)) {
        best = _Placement(
          x: rect.x,
          y: rect.y,
          width: width,
          height: height,
          rotated: false,
        );
        bestY = rect.y;
        bestX = rect.x;
      }
    }

    if (allowRotation && rect.width >= height && rect.height >= width) {
      if (rect.y < bestY || (rect.y == bestY && rect.x < bestX)) {
        best = _Placement(
          x: rect.x,
          y: rect.y,
          width: height,
          height: width,
          rotated: true,
        );
        bestY = rect.y;
        bestX = rect.x;
      }
    }
  }

  return best;
}

void _splitFreeRects(List<FreeRect> freeRects, _Placement placement) {
  final toAdd = <FreeRect>[];
  final toRemove = <FreeRect>[];

  for (final rect in freeRects) {
    if (_intersects(rect, placement)) {
      toRemove.add(rect);

      if (placement.x > rect.x) {
        toAdd.add(
          FreeRect(
            x: rect.x,
            y: rect.y,
            width: placement.x - rect.x,
            height: rect.height,
          ),
        );
      }

      if (placement.x + placement.width < rect.x + rect.width) {
        toAdd.add(
          FreeRect(
            x: placement.x + placement.width,
            y: rect.y,
            width: rect.x + rect.width - placement.x - placement.width,
            height: rect.height,
          ),
        );
      }

      if (placement.y > rect.y) {
        toAdd.add(
          FreeRect(
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: placement.y - rect.y,
          ),
        );
      }

      if (placement.y + placement.height < rect.y + rect.height) {
        toAdd.add(
          FreeRect(
            x: rect.x,
            y: placement.y + placement.height,
            width: rect.width,
            height: rect.y + rect.height - placement.y - placement.height,
          ),
        );
      }
    }
  }

  for (final rect in toRemove) {
    freeRects.remove(rect);
  }
  freeRects.addAll(toAdd);
}

bool _intersects(FreeRect rect, _Placement placement) {
  return rect.x < placement.x + placement.width &&
      rect.x + rect.width > placement.x &&
      rect.y < placement.y + placement.height &&
      rect.y + rect.height > placement.y;
}

void _pruneFreeRects(List<FreeRect> freeRects) {
  for (var i = 0; i < freeRects.length; i++) {
    for (var j = i + 1; j < freeRects.length; j++) {
      if (_contains(freeRects[j], freeRects[i])) {
        freeRects.removeAt(i);
        i--;
        break;
      }
      if (_contains(freeRects[i], freeRects[j])) {
        freeRects.removeAt(j);
        j--;
      }
    }
  }
}

bool _contains(FreeRect outer, FreeRect inner) {
  return outer.x <= inner.x &&
      outer.y <= inner.y &&
      outer.x + outer.width >= inner.x + inner.width &&
      outer.y + outer.height >= inner.y + inner.height;
}
