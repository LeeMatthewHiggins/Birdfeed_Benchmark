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
  AtlasResult? _atlasResult;
  List<SpriteLocation>? _spriteLocations;

  bool get hasLoadedFile => _atlas != null;
  String? get loadedFileName => _loadedFileName;
  List<SpriteLocation>? get spriteLocations => _spriteLocations;

  Future<bool> loadFile(Uint8List bytes, String fileName) async {
    try {
      if (fileName.toLowerCase().endsWith('.zip')) {
        return _loadZipFile(bytes, fileName);
      }
      return _loadImageFile(bytes, fileName);
    } on Exception catch (e, stackTrace) {
      debugPrint('Error loading file $fileName: $e');
      debugPrint('Stack trace: $stackTrace');
      _atlas = null;
      _shader = null;
      _loadedFileName = null;
      _atlasResult = null;
      _spriteLocations = null;
      return false;
    }
  }

  Future<bool> _loadImageFile(Uint8List bytes, String fileName) async {
    final oldAtlas = _atlas;
    final oldShader = _shader;
    final oldResult = _atlasResult;

    final atlas = await SpriteAtlas.fromBytes(bytes);
    final shader = await _loadShader();

    _atlas = atlas;
    _shader = shader;
    _loadedFileName = fileName;
    _atlasResult = null;
    _spriteLocations = null;

    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (oldResult != null) {
      oldResult.dispose();
    } else {
      oldAtlas?.dispose();
    }
    oldShader?.dispose();

    return true;
  }

  Future<bool> _loadZipFile(Uint8List bytes, String fileName) async {
    final oldAtlas = _atlas;
    final oldShader = _shader;
    final oldResult = _atlasResult;

    final loader = ZipAtlasLoader();
    final result = await loader.load(bytes);
    final shader = await _loadShader();

    _atlas = result.atlas;
    _shader = shader;
    _loadedFileName = fileName;
    _atlasResult = null;
    _spriteLocations = result.spriteLocations;

    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (oldResult != null) {
      oldResult.dispose();
    } else {
      oldAtlas?.dispose();
    }
    oldShader?.dispose();

    return true;
  }

  Stream<AtlasBuildProgress> generateEmojiAtlas() async* {
    final generator = EmojiAtlasGenerator();
    final sourceSprites = await generator.generateSourceSprites();

    final builder = IsolateAtlasBuilder(
      sizePreset: AtlasSizePreset.size2k,
    );

    await for (final progress in builder.buildWithProgress(sourceSprites)) {
      yield progress;
    }

    final oldAtlas = _atlas;
    final oldShader = _shader;
    final oldResult = _atlasResult;

    final result = builder.getResult();
    final atlasList = result.toSpriteAtlasList();

    if (atlasList.isEmpty) {
      throw StateError('Atlas generation produced no pages');
    }

    _atlasResult = result;
    _atlas = atlasList.first;
    _shader = await _loadShader();
    _spriteLocations = result.toSpriteLocationMap().values.toList();
    _loadedFileName = 'Emoji Atlas';

    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (oldResult != null) {
      oldResult.dispose();
    } else {
      oldAtlas?.dispose();
    }
    oldShader?.dispose();
  }

  Future<ui.FragmentShader> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'packages/megasprite/shaders/sprite_shader.frag',
    );
    return program.fragmentShader();
  }

  SpriteAtlas? get atlas => _atlas;
  ui.FragmentShader? get shader => _shader;
  AtlasResult? get atlasResult => _atlasResult;
  bool get canExport => _atlasResult != null;

  Future<Uint8List?> exportToZip() async {
    if (_atlasResult == null) return null;

    final exporter = ZipAtlasExporter();
    return exporter.export(_atlasResult!);
  }

  void dispose() {
    if (_atlasResult != null) {
      _atlasResult!.dispose();
    } else {
      _atlas?.dispose();
    }
    _shader?.dispose();
    _atlas = null;
    _shader = null;
    _loadedFileName = null;
    _atlasResult = null;
    _spriteLocations = null;
  }
}
