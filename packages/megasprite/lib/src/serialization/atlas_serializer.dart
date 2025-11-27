import 'package:megasprite/src/atlas/atlas_result.dart';
import 'package:megasprite/src/models/packed_sprite.dart';

enum SerializerFormat {
  texturePackerJson('json'),
  minimalJson('json'),
  yaml('yaml');

  const SerializerFormat(this.fileExtension);

  final String fileExtension;
}

abstract class AtlasSerializer {
  String serialize(AtlasResult result, String imageBaseName);

  String get fileExtension;

  static AtlasSerializer create(SerializerFormat format) {
    return switch (format) {
      SerializerFormat.texturePackerJson => TexturePackerSerializer(),
      SerializerFormat.minimalJson => MinimalJsonSerializer(),
      SerializerFormat.yaml => YamlSerializer(),
    };
  }
}

class TexturePackerSerializer implements AtlasSerializer {
  @override
  String get fileExtension => 'json';

  @override
  String serialize(AtlasResult result, String imageBaseName) {
    final buffer = StringBuffer()
      ..writeln('{')
      ..writeln('  "frames": {');

    var first = true;
    for (final page in result.pages) {
      for (final packed in page.packedSprites) {
        if (!first) buffer.writeln(',');
        first = false;
        _writeFrame(buffer, packed.identifier, packed, page.pageIndex);
      }
      for (final alias in page.aliases) {
        if (!first) buffer.writeln(',');
        first = false;
        _writeFrame(buffer, alias.identifier, alias.packedSprite, page.pageIndex);
      }
    }

    buffer
      ..writeln()
      ..writeln('  },')
      ..writeln('  "meta": {')
      ..writeln('    "app": "megasprite",')
      ..writeln('    "version": "1.0",')
      ..writeln('    "format": "RGBA8888",')
      ..write('    "pages": [');

    for (var i = 0; i < result.pages.length; i++) {
      if (i > 0) buffer.write(', ');
      final page = result.pages[i];
      buffer
        ..write('{"image": "$imageBaseName$i.png", ')
        ..write('"size": {"w": ${page.width}, "h": ${page.height}}}');
    }

    buffer
      ..writeln(']')
      ..writeln('  }')
      ..writeln('}');

    return buffer.toString();
  }

  void _writeFrame(
    StringBuffer buffer,
    String identifier,
    PackedSprite packed,
    int pageIndex,
  ) {
    final trimRect = packed.frame.trimRect;

    buffer
      ..writeln('    "$identifier": {')
      ..writeln('      "frame": {"x": ${packed.x}, "y": ${packed.y}, '
          '"w": ${packed.packedWidth}, "h": ${packed.packedHeight}},')
      ..writeln('      "rotated": ${packed.rotated},')
      ..writeln('      "trimmed": ${trimRect.isTrimmed},')
      ..writeln('      "spriteSourceSize": {"x": ${trimRect.offsetX}, '
          '"y": ${trimRect.offsetY}, "w": ${trimRect.width}, "h": ${trimRect.height}},')
      ..writeln('      "sourceSize": {"w": ${trimRect.originalWidth}, '
          '"h": ${trimRect.originalHeight}},')
      ..write('      "page": $pageIndex')
      ..write('\n    }');
  }
}

class MinimalJsonSerializer implements AtlasSerializer {
  @override
  String get fileExtension => 'json';

  @override
  String serialize(AtlasResult result, String imageBaseName) {
    final buffer = StringBuffer()
      ..writeln('{')
      ..writeln('  "pages": [');

    for (var i = 0; i < result.pages.length; i++) {
      final page = result.pages[i];
      if (i > 0) buffer.writeln(',');
      buffer
        ..write('    {"image": "$imageBaseName$i.png", ')
        ..write('"width": ${page.width}, "height": ${page.height}}');
    }

    buffer
      ..writeln()
      ..writeln('  ],')
      ..writeln('  "sprites": {');

    var first = true;
    for (final page in result.pages) {
      for (final packed in page.packedSprites) {
        if (!first) buffer.writeln(',');
        first = false;
        _writeSprite(buffer, packed.identifier, packed, page.pageIndex);
      }
      for (final alias in page.aliases) {
        if (!first) buffer.writeln(',');
        first = false;
        _writeSprite(buffer, alias.identifier, alias.packedSprite, page.pageIndex);
      }
    }

    buffer
      ..writeln()
      ..writeln('  }')
      ..writeln('}');

    return buffer.toString();
  }

  void _writeSprite(
    StringBuffer buffer,
    String identifier,
    PackedSprite packed,
    int pageIndex,
  ) {
    final trimRect = packed.frame.trimRect;

    buffer
      ..write('    "$identifier": {')
      ..write('"p": $pageIndex, ')
      ..write('"x": ${packed.x}, "y": ${packed.y}, ')
      ..write('"w": ${packed.packedWidth}, "h": ${packed.packedHeight}');

    if (packed.rotated) {
      buffer.write(', "r": true');
    }

    if (trimRect.isTrimmed) {
      buffer
        ..write(', "ox": ${trimRect.offsetX}, "oy": ${trimRect.offsetY}')
        ..write(', "ow": ${trimRect.originalWidth}, "oh": ${trimRect.originalHeight}');
    }

    buffer.write('}');
  }
}

class YamlSerializer implements AtlasSerializer {
  @override
  String get fileExtension => 'yaml';

  @override
  String serialize(AtlasResult result, String imageBaseName) {
    final buffer = StringBuffer()..writeln('pages:');

    for (var i = 0; i < result.pages.length; i++) {
      final page = result.pages[i];
      buffer
        ..writeln('  - image: $imageBaseName$i.png')
        ..writeln('    width: ${page.width}')
        ..writeln('    height: ${page.height}');
    }

    buffer
      ..writeln()
      ..writeln('sprites:');

    for (final page in result.pages) {
      for (final packed in page.packedSprites) {
        _writeSprite(buffer, packed.identifier, packed, page.pageIndex);
      }
      for (final alias in page.aliases) {
        _writeSprite(buffer, alias.identifier, alias.packedSprite, page.pageIndex);
      }
    }

    return buffer.toString();
  }

  void _writeSprite(
    StringBuffer buffer,
    String identifier,
    PackedSprite packed,
    int pageIndex,
  ) {
    final trimRect = packed.frame.trimRect;

    buffer
      ..writeln('  $identifier:')
      ..writeln('    page: $pageIndex')
      ..writeln('    x: ${packed.x}')
      ..writeln('    y: ${packed.y}')
      ..writeln('    width: ${packed.packedWidth}')
      ..writeln('    height: ${packed.packedHeight}');

    if (packed.rotated) {
      buffer.writeln('    rotated: true');
    }

    if (trimRect.isTrimmed) {
      buffer
        ..writeln('    trim:')
        ..writeln('      x: ${trimRect.offsetX}')
        ..writeln('      y: ${trimRect.offsetY}')
        ..writeln('      originalWidth: ${trimRect.originalWidth}')
        ..writeln('      originalHeight: ${trimRect.originalHeight}');
    }
  }
}
