import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:megasprite/src/atlas/atlas_result.dart';
import 'package:megasprite/src/serialization/atlas_serializer.dart';

class ZipAtlasExporter {
  ZipAtlasExporter({
    this.format = SerializerFormat.minimalJson,
    this.imageBaseName = 'atlas',
  });

  final SerializerFormat format;
  final String imageBaseName;

  Future<Uint8List> export(AtlasResult result) async {
    final archive = Archive();
    final serializer = AtlasSerializer.create(format);

    final jsonContent = serializer.serialize(result, imageBaseName);
    archive.addFile(
      ArchiveFile(
        'atlas.${serializer.fileExtension}',
        jsonContent.length,
        jsonContent.codeUnits,
      ),
    );

    for (var i = 0; i < result.pages.length; i++) {
      final page = result.pages[i];
      final pngBytes = await _encodePng(page.image);
      archive.addFile(
        ArchiveFile(
          '$imageBaseName$i.png',
          pngBytes.length,
          pngBytes,
        ),
      );
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw ZipAtlasExportException('Failed to encode zip archive');
    }

    return Uint8List.fromList(zipData);
  }

  Future<Uint8List> _encodePng(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw ZipAtlasExportException('Failed to encode image as PNG');
    }
    return byteData.buffer.asUint8List();
  }
}

class ZipAtlasExportException implements Exception {
  ZipAtlasExportException(this.message);

  final String message;

  @override
  String toString() => 'ZipAtlasExportException: $message';
}
