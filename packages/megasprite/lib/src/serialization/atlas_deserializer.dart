import 'dart:convert';
import 'dart:ui';

import 'package:megasprite/src/atlas/atlas_result.dart';
import 'package:megasprite/src/sprite.dart';

class AtlasDescriptor {
  const AtlasDescriptor({
    required this.pages,
    required this.sprites,
  });

  final List<PageDescriptor> pages;
  final Map<String, SpriteDescriptor> sprites;
}

class PageDescriptor {
  const PageDescriptor({
    required this.imagePath,
    required this.width,
    required this.height,
  });

  final String imagePath;
  final int width;
  final int height;
}

class SpriteDescriptor {
  const SpriteDescriptor({
    required this.pageIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotated = false,
    this.trimOffsetX = 0,
    this.trimOffsetY = 0,
    this.originalWidth,
    this.originalHeight,
  });

  final int pageIndex;
  final int x;
  final int y;
  final int width;
  final int height;
  final bool rotated;
  final int trimOffsetX;
  final int trimOffsetY;
  final int? originalWidth;
  final int? originalHeight;

  SpriteLocation toSpriteLocation() {
    return SpriteLocation(
      pageIndex: pageIndex,
      sprite: Sprite(
        rect: Rect.fromLTWH(
          x.toDouble(),
          y.toDouble(),
          width.toDouble(),
          height.toDouble(),
        ),
        sourceRect: Rect.fromLTWH(
          x.toDouble(),
          y.toDouble(),
          width.toDouble(),
          height.toDouble(),
        ),
        trimOffsetX: trimOffsetX,
        trimOffsetY: trimOffsetY,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        rotated: rotated,
      ),
      trimOffsetX: trimOffsetX,
      trimOffsetY: trimOffsetY,
      originalWidth: originalWidth ?? width,
      originalHeight: originalHeight ?? height,
      rotated: rotated,
    );
  }
}

abstract class AtlasDeserializer {
  AtlasDescriptor deserialize(String content);

  static AtlasDeserializer create(DeserializerFormat format) {
    return switch (format) {
      DeserializerFormat.texturePackerJson => TexturePackerDeserializer(),
      DeserializerFormat.minimalJson => MinimalJsonDeserializer(),
    };
  }

  static DeserializerFormat? detectFormat(String content) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      if (json.containsKey('frames') && json.containsKey('meta')) {
        return DeserializerFormat.texturePackerJson;
      }
      if (json.containsKey('pages') && json.containsKey('sprites')) {
        return DeserializerFormat.minimalJson;
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

enum DeserializerFormat {
  texturePackerJson,
  minimalJson,
}

class TexturePackerDeserializer implements AtlasDeserializer {
  @override
  AtlasDescriptor deserialize(String content) {
    final json = jsonDecode(content) as Map<String, dynamic>;

    final meta = json['meta'] as Map<String, dynamic>;
    final pagesJson = meta['pages'] as List<dynamic>;
    final framesJson = json['frames'] as Map<String, dynamic>;

    final pages = <PageDescriptor>[];
    for (final pageJson in pagesJson) {
      final page = pageJson as Map<String, dynamic>;
      final size = page['size'] as Map<String, dynamic>;
      pages.add(
        PageDescriptor(
          imagePath: page['image'] as String,
          width: size['w'] as int,
          height: size['h'] as int,
        ),
      );
    }

    final sprites = <String, SpriteDescriptor>{};
    for (final entry in framesJson.entries) {
      final identifier = entry.key;
      final frameData = entry.value as Map<String, dynamic>;
      final frame = frameData['frame'] as Map<String, dynamic>;
      final spriteSourceSize =
          frameData['spriteSourceSize'] as Map<String, dynamic>?;
      final sourceSize = frameData['sourceSize'] as Map<String, dynamic>?;

      sprites[identifier] = SpriteDescriptor(
        pageIndex: (frameData['page'] as int?) ?? 0,
        x: frame['x'] as int,
        y: frame['y'] as int,
        width: frame['w'] as int,
        height: frame['h'] as int,
        rotated: (frameData['rotated'] as bool?) ?? false,
        trimOffsetX: (spriteSourceSize?['x'] as int?) ?? 0,
        trimOffsetY: (spriteSourceSize?['y'] as int?) ?? 0,
        originalWidth: sourceSize?['w'] as int?,
        originalHeight: sourceSize?['h'] as int?,
      );
    }

    return AtlasDescriptor(pages: pages, sprites: sprites);
  }
}

class MinimalJsonDeserializer implements AtlasDeserializer {
  @override
  AtlasDescriptor deserialize(String content) {
    final json = jsonDecode(content) as Map<String, dynamic>;

    final pagesJson = json['pages'] as List<dynamic>;
    final spritesJson = json['sprites'] as Map<String, dynamic>;

    final pages = <PageDescriptor>[];
    for (final pageJson in pagesJson) {
      final page = pageJson as Map<String, dynamic>;
      pages.add(
        PageDescriptor(
          imagePath: page['image'] as String,
          width: page['width'] as int,
          height: page['height'] as int,
        ),
      );
    }

    final sprites = <String, SpriteDescriptor>{};
    for (final entry in spritesJson.entries) {
      final identifier = entry.key;
      final spriteData = entry.value as Map<String, dynamic>;

      sprites[identifier] = SpriteDescriptor(
        pageIndex: spriteData['p'] as int,
        x: spriteData['x'] as int,
        y: spriteData['y'] as int,
        width: spriteData['w'] as int,
        height: spriteData['h'] as int,
        rotated: (spriteData['r'] as bool?) ?? false,
        trimOffsetX: (spriteData['ox'] as int?) ?? 0,
        trimOffsetY: (spriteData['oy'] as int?) ?? 0,
        originalWidth: spriteData['ow'] as int?,
        originalHeight: spriteData['oh'] as int?,
      );
    }

    return AtlasDescriptor(pages: pages, sprites: sprites);
  }
}
