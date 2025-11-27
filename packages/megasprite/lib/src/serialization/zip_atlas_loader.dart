import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:megasprite/src/atlas/atlas_result.dart';
import 'package:megasprite/src/serialization/atlas_deserializer.dart';
import 'package:megasprite/src/sprite_atlas.dart';

class ZipAtlasLoadResult {
  const ZipAtlasLoadResult({
    required this.atlas,
    required this.spriteLocations,
    required this.descriptor,
  });

  final SpriteAtlas atlas;
  final List<SpriteLocation> spriteLocations;
  final AtlasDescriptor descriptor;

  void dispose() {
    atlas.dispose();
  }
}

class ZipAtlasLoader {
  static const List<String> _supportedJsonFiles = [
    'atlas.json',
    'sprites.json',
    'spritesheet.json',
  ];

  Future<ZipAtlasLoadResult> load(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final jsonFile = _findJsonFile(archive);
    if (jsonFile == null) {
      throw ZipAtlasException('No atlas descriptor JSON found in zip');
    }

    final jsonContent = String.fromCharCodes(jsonFile.content as List<int>);
    final format = AtlasDeserializer.detectFormat(jsonContent);
    if (format == null) {
      throw ZipAtlasException('Unknown atlas JSON format');
    }

    final deserializer = AtlasDeserializer.create(format);
    final descriptor = deserializer.deserialize(jsonContent);

    if (descriptor.pages.isEmpty) {
      throw ZipAtlasException('Atlas descriptor contains no pages');
    }

    if (descriptor.pages.length > 1) {
      throw ZipAtlasException(
        'Only single-page atlases are supported. '
        'Found ${descriptor.pages.length} pages.',
      );
    }

    final page = descriptor.pages.first;
    final imageFile = _findImageFile(archive, page.imagePath);
    if (imageFile == null) {
      throw ZipAtlasException('Atlas image not found: ${page.imagePath}');
    }

    final imageBytes = Uint8List.fromList(imageFile.content as List<int>);
    final atlas = await SpriteAtlas.fromBytes(imageBytes);

    final spriteLocations = descriptor.sprites.values
        .map((sprite) => sprite.toSpriteLocation())
        .toList();

    return ZipAtlasLoadResult(
      atlas: atlas,
      spriteLocations: spriteLocations,
      descriptor: descriptor,
    );
  }

  ArchiveFile? _findJsonFile(Archive archive) {
    for (final fileName in _supportedJsonFiles) {
      final file = archive.findFile(fileName);
      if (file != null) return file;
    }

    for (final file in archive.files) {
      if (file.name.endsWith('.json')) {
        return file;
      }
    }

    return null;
  }

  ArchiveFile? _findImageFile(Archive archive, String imagePath) {
    var file = archive.findFile(imagePath);
    if (file != null) return file;

    final baseName = imagePath.split('/').last;
    file = archive.findFile(baseName);
    if (file != null) return file;

    for (final archiveFile in archive.files) {
      if (archiveFile.name.endsWith('.png') ||
          archiveFile.name.endsWith('.jpg') ||
          archiveFile.name.endsWith('.jpeg') ||
          archiveFile.name.endsWith('.webp')) {
        return archiveFile;
      }
    }

    return null;
  }
}

class ZipAtlasException implements Exception {
  ZipAtlasException(this.message);

  final String message;

  @override
  String toString() => 'ZipAtlasException: $message';
}
