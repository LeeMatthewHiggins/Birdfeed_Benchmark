import 'package:archive/archive.dart';
import 'package:atlas_creator/screens/atlas_creator_screen.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class SpriteDropHandler {
  static const _supportedExtensions = [
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
    '.bmp',
  ];

  Future<List<SpriteEntry>> processDropDetails(
    DropDoneDetails details, {
    String? folderPrefix,
  }) async {
    final entries = <SpriteEntry>[];

    for (final file in details.files) {
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();

      if (name.endsWith('.zip')) {
        entries.addAll(await extractZip(bytes, folderPrefix: folderPrefix));
      } else if (isImageFile(name)) {
        entries.add(
          SpriteEntry(
            identifier: _buildIdentifier(file.name, folderPrefix),
            bytes: bytes,
          ),
        );
      }
    }

    return entries;
  }

  Future<List<SpriteEntry>> processPickerFiles(
    List<PlatformFile> files, {
    String? folderPrefix,
  }) async {
    final entries = <SpriteEntry>[];

    for (final file in files) {
      if (file.bytes == null) continue;

      final name = file.name.toLowerCase();

      if (name.endsWith('.zip')) {
        entries.addAll(
          await extractZip(file.bytes!, folderPrefix: folderPrefix),
        );
      } else if (isImageFile(name)) {
        entries.add(
          SpriteEntry(
            identifier: _buildIdentifier(file.name, folderPrefix),
            bytes: file.bytes!,
          ),
        );
      }
    }

    return entries;
  }

  Future<List<SpriteEntry>> extractZip(
    Uint8List bytes, {
    String? folderPrefix,
  }) async {
    final entries = <SpriteEntry>[];

    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.isFile && isImageFile(file.name.toLowerCase())) {
          final content = file.content as List<int>;
          entries.add(
            SpriteEntry(
              identifier: _buildIdentifier(file.name, folderPrefix),
              bytes: Uint8List.fromList(content),
            ),
          );
        }
      }
    } on Exception catch (e) {
      debugPrint('Failed to extract zip: $e');
    }

    return entries;
  }

  bool isImageFile(String name) {
    final fileName = name.split('/').last;
    if (fileName.startsWith('.') || fileName.startsWith('._')) {
      return false;
    }
    return _supportedExtensions.any(name.endsWith);
  }

  String _buildIdentifier(String originalPath, String? folderPrefix) {
    if (folderPrefix == null || folderPrefix.isEmpty) {
      return originalPath;
    }
    return '$folderPrefix/$originalPath';
  }
}
