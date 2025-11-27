import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:megasprite/src/atlas/atlas_builder_config.dart';
import 'package:megasprite/src/atlas/atlas_page.dart';
import 'package:megasprite/src/atlas/atlas_result.dart';
import 'package:megasprite/src/atlas/image_trimmer.dart';
import 'package:megasprite/src/models/packed_sprite.dart';
import 'package:megasprite/src/models/source_sprite.dart';
import 'package:megasprite/src/models/sprite_frame.dart';
import 'package:megasprite/src/packing/max_rects_packer.dart';
import 'package:megasprite/src/packing/packing_strategy.dart';

class AtlasBuilder {
  AtlasBuilder({
    this.sizePreset = AtlasBuilderConfig.defaultSizePreset,
    this.padding = AtlasBuilderConfig.defaultPadding,
    this.allowRotation = AtlasBuilderConfig.defaultAllowRotation,
    PackingStrategy? packingStrategy,
  }) : packingStrategy = packingStrategy ?? MaxRectsPacker();

  final AtlasSizePreset sizePreset;
  final int padding;
  final bool allowRotation;
  final PackingStrategy packingStrategy;

  Future<AtlasResult> build(List<SourceSprite> sprites) async {
    final frames = await _processSprites(sprites);
    final deduplicationResult = _deduplicateFrames(frames);

    final pages = await _packFrames(
      deduplicationResult.uniqueFrames,
      deduplicationResult.hashToFrame,
      deduplicationResult.duplicates,
    );

    return AtlasResult(
      pages: pages,
      totalSpriteCount: sprites.length,
      uniqueSpriteCount: deduplicationResult.uniqueFrames.length,
      duplicateCount: deduplicationResult.duplicates.length,
    );
  }

  Future<List<SpriteFrame>> _processSprites(List<SourceSprite> sprites) async {
    final frames = <SpriteFrame>[];

    for (final sprite in sprites) {
      final image = await _decodeImage(sprite.imageBytes, sprite.identifier);
      final trimResult = await ImageTrimmer.trim(image);

      ui.Image trimmedImage;
      if (trimResult.trimRect.isEmpty) {
        trimmedImage = image;
      } else {
        trimmedImage = await ImageTrimmer.createImageFromPixels(
          trimResult.trimmedPixels,
          trimResult.trimRect.width,
          trimResult.trimRect.height,
        );
        image.dispose();
      }

      frames.add(
        SpriteFrame(
          identifier: sprite.identifier,
          trimmedImage: trimmedImage,
          trimRect: trimResult.trimRect,
          pixelHash: trimResult.pixelHash,
        ),
      );
    }

    return frames;
  }

  _DeduplicationResult _deduplicateFrames(List<SpriteFrame> frames) {
    final hashToFrame = <int, SpriteFrame>{};
    final uniqueFrames = <SpriteFrame>[];
    final duplicates = <String, SpriteFrame>{};

    for (final frame in frames) {
      if (frame.isEmpty) {
        uniqueFrames.add(frame);
        continue;
      }

      final existingFrame = hashToFrame[frame.pixelHash];
      if (existingFrame != null) {
        duplicates[frame.identifier] = existingFrame;
      } else {
        hashToFrame[frame.pixelHash] = frame;
        uniqueFrames.add(frame);
      }
    }

    return _DeduplicationResult(
      uniqueFrames: uniqueFrames,
      hashToFrame: hashToFrame,
      duplicates: duplicates,
    );
  }

  Future<List<AtlasPage>> _packFrames(
    List<SpriteFrame> uniqueFrames,
    Map<int, SpriteFrame> hashToFrame,
    Map<String, SpriteFrame> duplicates,
  ) async {
    final pages = <AtlasPage>[];
    var remaining = List<SpriteFrame>.from(uniqueFrames);
    var pageIndex = 0;

    while (remaining.isNotEmpty) {
      packingStrategy.reset();

      final result = packingStrategy.pack(
        sprites: remaining,
        atlasWidth: sizePreset.dimension,
        atlasHeight: sizePreset.dimension,
        padding: padding,
        allowRotation: allowRotation,
        pageIndex: pageIndex,
      );

      if (result.packed.isEmpty && result.overflow.isNotEmpty) {
        final oversized = result.overflow.first;
        throw AtlasBuildException(
          'Sprite "${oversized.identifier}" (${oversized.width}x${oversized.height}) '
          'is too large for atlas size ${sizePreset.dimension}x${sizePreset.dimension}',
        );
      }

      final aliases = _createAliases(result.packed, duplicates);

      final atlasImage = await _compositeAtlasImage(
        result.packed,
        sizePreset.dimension,
        sizePreset.dimension,
      );

      pages.add(
        AtlasPage(
          image: atlasImage,
          packedSprites: result.packed,
          aliases: aliases,
          pageIndex: pageIndex,
          width: sizePreset.dimension,
          height: sizePreset.dimension,
        ),
      );

      remaining = result.overflow;
      pageIndex++;
    }

    return pages;
  }

  List<SpriteAlias> _createAliases(
    List<PackedSprite> packed,
    Map<String, SpriteFrame> duplicates,
  ) {
    final aliases = <SpriteAlias>[];

    final identifierToPacked = <String, PackedSprite>{};
    for (final sprite in packed) {
      identifierToPacked[sprite.identifier] = sprite;
    }

    for (final entry in duplicates.entries) {
      final originalFrame = entry.value;
      final packedSprite = identifierToPacked[originalFrame.identifier];
      if (packedSprite != null) {
        aliases.add(
          SpriteAlias(
            identifier: entry.key,
            packedSprite: packedSprite,
          ),
        );
      }
    }

    return aliases;
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

  Future<ui.Image> _decodeImage(Uint8List bytes, String identifier) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } on Exception catch (e) {
      throw AtlasBuildException(
        'Failed to decode image "$identifier": $e',
      );
    }
  }
}

class _DeduplicationResult {
  const _DeduplicationResult({
    required this.uniqueFrames,
    required this.hashToFrame,
    required this.duplicates,
  });

  final List<SpriteFrame> uniqueFrames;
  final Map<int, SpriteFrame> hashToFrame;
  final Map<String, SpriteFrame> duplicates;
}

class AtlasBuildException implements Exception {
  AtlasBuildException(this.message);

  final String message;

  @override
  String toString() => 'AtlasBuildException: $message';
}
