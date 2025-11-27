import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atlas_creator/services/web_download_stub.dart'
    if (dart.library.js_interop) 'package:atlas_creator/services/web_download.dart';
import 'package:atlas_creator/widgets/export_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:megasprite/megasprite.dart';

class AtlasCreatorService {
  Stream<AtlasBuildProgress> buildAtlasWithProgress({
    required List<SourceSprite> sprites,
    required AtlasSizePreset sizePreset,
    required int padding,
    required bool allowRotation,
    required int trimTolerance,
    required PackingAlgorithm packingAlgorithm,
  }) {
    _builder = IsolateAtlasBuilder(
      sizePreset: sizePreset,
      padding: padding,
      allowRotation: allowRotation,
      trimTolerance: trimTolerance,
      packingAlgorithm: packingAlgorithm,
    );

    return _builder!.buildWithProgress(sprites);
  }

  IsolateAtlasBuilder? _builder;

  AtlasResult getResult() {
    if (_builder == null) {
      throw StateError('No builder available');
    }
    return _builder!.getResult();
  }

  Future<bool> exportAtlas(
    AtlasResult result,
    ExportSettings settings,
  ) async {
    if (settings.exportAsZip) {
      return _exportAtlasAsZip(result, settings);
    }
    if (kIsWeb) {
      return _exportAtlasWeb(result, settings);
    }
    return _exportAtlasNative(result, settings);
  }

  Future<bool> _exportAtlasAsZip(
    AtlasResult result,
    ExportSettings settings,
  ) async {
    final exporter = ZipAtlasExporter(
      format: settings.metadataFormat,
      imageBaseName: '${settings.baseName}_',
    );
    final zipBytes = await exporter.export(result);

    if (kIsWeb) {
      downloadFile('${settings.baseName}.zip', zipBytes);
      return true;
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Atlas ZIP',
      fileName: '${settings.baseName}.zip',
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: zipBytes,
    );

    return savePath != null;
  }

  Future<bool> _exportAtlasWeb(
    AtlasResult result,
    ExportSettings settings,
  ) async {
    final serializer = AtlasSerializer.create(settings.metadataFormat);
    final metadata = serializer.serialize(result, '${settings.baseName}_');
    final metadataBytes = Uint8List.fromList(metadata.codeUnits);
    final metadataFileName =
        '${settings.baseName}.${serializer.fileExtension}';

    downloadFile(metadataFileName, metadataBytes);

    for (var i = 0; i < result.pages.length; i++) {
      final page = result.pages[i];
      final imageBytes = await _encodePng(page.image);
      final imageFileName = '${settings.baseName}_$i.png';

      downloadFile(imageFileName, imageBytes);
    }

    return true;
  }

  Future<bool> _exportAtlasNative(
    AtlasResult result,
    ExportSettings settings,
  ) async {
    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Output Directory',
    );

    if (outputDir == null) return false;

    final serializer = AtlasSerializer.create(settings.metadataFormat);
    final metadata = serializer.serialize(result, '${settings.baseName}_');

    final metadataBytes = Uint8List.fromList(metadata.codeUnits);
    final metadataFileName =
        '${settings.baseName}.${serializer.fileExtension}';

    await FilePicker.platform.saveFile(
      dialogTitle: 'Save $metadataFileName',
      fileName: metadataFileName,
      initialDirectory: outputDir,
      bytes: metadataBytes,
    );

    for (var i = 0; i < result.pages.length; i++) {
      final page = result.pages[i];
      final imageBytes = await _encodePng(page.image);
      final imageFileName = '${settings.baseName}_$i.png';

      await FilePicker.platform.saveFile(
        dialogTitle: 'Save $imageFileName',
        fileName: imageFileName,
        initialDirectory: outputDir,
        bytes: imageBytes,
      );
    }

    return true;
  }

  Future<Uint8List> _encodePng(ui.Image image) async {
    final byteData = await image.toByteData();
    if (byteData == null) return Uint8List(0);

    final width = image.width;
    final height = image.height;
    final pixels = byteData.buffer.asUint8List();

    final imgImage = img.Image(width: width, height: height, numChannels: 4);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        imgImage.setPixelRgba(
          x,
          y,
          pixels[i],
          pixels[i + 1],
          pixels[i + 2],
          pixels[i + 3],
        );
      }
    }

    return Uint8List.fromList(img.encodePng(imgImage));
  }
}
