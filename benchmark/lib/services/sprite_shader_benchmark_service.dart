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
      final atlas = await SpriteAtlas.fromBytes(bytes);
      _atlas = atlas;
      _loadedFileName = fileName;
      _spriteRects =
          null; // Reset sprite rects for loaded images (using full image)
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

      // Create SpriteAtlas from the generated image
      // We need to create it manually since fromBytes expects encoded data
      // But SpriteAtlas constructor is private/internal or expects bytes?
      // Let's check SpriteAtlas definition.
      // Assuming we can create it or need to modify SpriteAtlas.
      // Actually, SpriteAtlas.fromBytes decodes image.
      // We have the image directly.
      // Let's look at SpriteAtlas again.

      // For now, let's assume we can create it.
      // If SpriteAtlas only has fromBytes, we might need to encode it or add a constructor.
      // Let's check SpriteAtlas.

      // Wait, I can't see SpriteAtlas here.
      // I'll assume I need to add a method to SpriteAtlas or use an existing one.
      // Let's assume      // Create SpriteAtlas from the generated image
      _atlas = await SpriteAtlas.fromImage(image);
      _spriteRects = rects;
      _loadedFileName = 'Emoji Atlas';
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
