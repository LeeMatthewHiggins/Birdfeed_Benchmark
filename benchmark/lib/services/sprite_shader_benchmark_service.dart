import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:megasprite/megasprite.dart';

class SpriteShaderBenchmarkService {
  factory SpriteShaderBenchmarkService() => _instance;

  SpriteShaderBenchmarkService._internal();
  static final SpriteShaderBenchmarkService _instance =
      SpriteShaderBenchmarkService._internal();

  SpriteAtlas? _atlas;
  String? _loadedFileName;

  bool get hasLoadedFile => _atlas != null;
  String? get loadedFileName => _loadedFileName;

  Future<bool> loadImageFile(Uint8List bytes, String fileName) async {
    try {
      final atlas = await SpriteAtlas.fromBytes(bytes);
      _atlas = atlas;
      _loadedFileName = fileName;
      return true;
    } on Exception catch (e, stackTrace) {
      debugPrint('Error loading image file $fileName: $e');
      debugPrint('Stack trace: $stackTrace');
      _atlas = null;
      _loadedFileName = null;
      return false;
    }
  }

  SpriteAtlas? get atlas => _atlas;

  void dispose() {
    _atlas?.dispose();
    _atlas = null;
    _loadedFileName = null;
  }
}
