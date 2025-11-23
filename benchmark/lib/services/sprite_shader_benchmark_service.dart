import 'dart:async';
import 'dart:ui';

import 'package:benchmark/services/emoji_atlas_generator.dart';
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

  List<Rect>? _spriteRects;
  List<Rect>? get spriteRects => _spriteRects;

  Future<bool> loadImageFile(Uint8List bytes, String fileName) async {
    try {
      final oldAtlas = _atlas;
      final atlas = await SpriteAtlas.fromBytes(bytes);
      _atlas = atlas;
      _loadedFileName = fileName;
      _spriteRects = null;

      await Future<void>.delayed(const Duration(milliseconds: 100));
      oldAtlas?.dispose();

      return true;
    } on Exception catch (e, stackTrace) {
      debugPrint('Error loading image file $fileName: $e');
      debugPrint('Stack trace: $stackTrace');
      _atlas = null;
      _loadedFileName = null;
      _spriteRects = null;
      return false;
    }
  }

  Future<bool> generateEmojiAtlas() async {
    try {
      final generator = EmojiAtlasGenerator();
      final (image, rects) = await generator.generate();

      final oldAtlas = _atlas;
      _atlas = await SpriteAtlas.fromImage(image);
      _spriteRects = rects;
      _loadedFileName = 'Emoji Atlas';

      await Future<void>.delayed(const Duration(milliseconds: 100));
      oldAtlas?.dispose();

      return true;
    } on Exception catch (e, stackTrace) {
      debugPrint('Error generating emoji atlas: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  SpriteAtlas? get atlas => _atlas;

  void dispose() {
    _atlas?.dispose();
    _atlas = null;
    _loadedFileName = null;
    _spriteRects = null;
  }
}
