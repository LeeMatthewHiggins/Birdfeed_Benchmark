import 'dart:async';
import 'dart:ui' as ui;

import 'package:benchmark/services/emoji_atlas_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:megasprite/megasprite.dart';

class SpriteShaderBenchmarkService {
  factory SpriteShaderBenchmarkService() => _instance;

  SpriteShaderBenchmarkService._internal();
  static final SpriteShaderBenchmarkService _instance =
      SpriteShaderBenchmarkService._internal();

  SpriteAtlas? _atlas;
  ui.FragmentShader? _shader;
  String? _loadedFileName;

  bool get hasLoadedFile => _atlas != null;
  String? get loadedFileName => _loadedFileName;

  List<ui.Rect>? _spriteRects;
  List<ui.Rect>? get spriteRects => _spriteRects;

  Future<bool> loadImageFile(Uint8List bytes, String fileName) async {
    try {
      final oldAtlas = _atlas;
      final oldShader = _shader;

      final atlas = await SpriteAtlas.fromBytes(bytes);
      final shader = await _loadShader();

      _atlas = atlas;
      _shader = shader;
      _loadedFileName = fileName;
      _spriteRects = null;

      await Future<void>.delayed(const Duration(milliseconds: 100));
      oldAtlas?.dispose();
      oldShader?.dispose();

      return true;
    } on Exception catch (e, stackTrace) {
      debugPrint('Error loading image file $fileName: $e');
      debugPrint('Stack trace: $stackTrace');
      _atlas = null;
      _shader = null;
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
      final oldShader = _shader;

      _atlas = await SpriteAtlas.fromImage(image);
      _shader = await _loadShader();
      _spriteRects = rects;
      _loadedFileName = 'Emoji Atlas';

      await Future<void>.delayed(const Duration(milliseconds: 100));
      oldAtlas?.dispose();
      oldShader?.dispose();

      return true;
    } on Exception catch (e, stackTrace) {
      debugPrint('Error generating emoji atlas: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<ui.FragmentShader> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'packages/megasprite/shaders/sprite_shader.frag',
    );
    return program.fragmentShader();
  }

  SpriteAtlas? get atlas => _atlas;
  ui.FragmentShader? get shader => _shader;

  void dispose() {
    _atlas?.dispose();
    _shader?.dispose();
    _atlas = null;
    _shader = null;
    _loadedFileName = null;
    _spriteRects = null;
  }
}
