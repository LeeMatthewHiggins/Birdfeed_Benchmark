import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:megasprite/megasprite.dart';

class _EmojiConstants {
  const _EmojiConstants._();

  static const int spriteSize = 128;
  static const double fontSize = 96;
}

class EmojiAtlasGenerator {
  static const List<String> emojis = [
    '😀',
    '😎',
    '🥳',
    '👽',
    '👻',
    '🤖',
    '💩',
    '🐱',
    '🐶',
    '🦄',
    '🔥',
    '🌈',
    '🍕',
    '🚀',
    '⚽️',
    '🎉',
    '❤️',
    '💔',
    '💯',
    '💢',
    '💥',
    '💫',
    '💦',
    '💨',
    '🕳️',
    '💣',
    '💬',
    '👁️‍🗨️',
    '🗨️',
    '🗯️',
    '💭',
  ];

  Future<List<SourceSprite>> generateSourceSprites() async {
    final sprites = <SourceSprite>[];
    final textStyle = kIsWeb
        ? GoogleFonts.notoColorEmoji(fontSize: _EmojiConstants.fontSize)
        : const TextStyle(fontSize: _EmojiConstants.fontSize);

    for (var i = 0; i < emojis.length; i++) {
      final bytes = await _renderEmojiToPng(emojis[i], textStyle);
      sprites.add(
        SourceSprite(
          identifier: 'emoji_$i',
          imageBytes: bytes,
        ),
      );
    }

    return sprites;
  }

  Future<Uint8List> _renderEmojiToPng(String emoji, TextStyle style) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final textPainter = TextPainter(
      text: TextSpan(text: emoji, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(
        minWidth: _EmojiConstants.spriteSize.toDouble(),
        maxWidth: _EmojiConstants.spriteSize.toDouble(),
      );

    final offset = Offset(
      (_EmojiConstants.spriteSize - textPainter.width) / 2,
      (_EmojiConstants.spriteSize - textPainter.height) / 2,
    );

    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _EmojiConstants.spriteSize,
      _EmojiConstants.spriteSize,
    );
    picture.dispose();

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return byteData!.buffer.asUint8List();
  }
}
