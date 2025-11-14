import 'dart:async';
import 'dart:ui' as ui;

import 'package:benchmark/ecs/components/sprite_shader_content_component.dart';
import 'package:flutter/foundation.dart';

class SpriteShaderBenchmarkService {
  factory SpriteShaderBenchmarkService() => _instance;

  SpriteShaderBenchmarkService._internal();
  static final SpriteShaderBenchmarkService _instance =
      SpriteShaderBenchmarkService._internal();

  ui.Image? _image;
  ui.FragmentShader? _shader;
  String? _loadedFileName;

  bool get hasLoadedFile => _image != null && _shader != null;
  String? get loadedFileName => _loadedFileName;

  Future<bool> loadImageFile(Uint8List bytes, String fileName) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final program =
          await ui.FragmentProgram.fromAsset('shaders/sprite_shader.frag');
      _shader = program.fragmentShader();

      _image = image;
      _loadedFileName = fileName;
      return true;
    } on Exception catch (e, stackTrace) {
      debugPrint('Error loading image file $fileName: $e');
      debugPrint('Stack trace: $stackTrace');
      _image = null;
      _shader = null;
      _loadedFileName = null;
      return false;
    }
  }

  SpriteShaderContentComponent? createSpriteShaderContent() {
    if (_image == null || _shader == null) {
      return null;
    }

    return SpriteShaderContentComponent(
      image: _image!,
      shader: _shader!,
    );
  }

  void dispose() {
    _image?.dispose();
    _shader?.dispose();
    _image = null;
    _shader = null;
    _loadedFileName = null;
  }
}
