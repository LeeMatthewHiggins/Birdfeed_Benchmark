import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmojiAtlasGenerator {
  static const int _atlasSize = 1024;
  static const int _emojiSize = 128;

  static const List<String> _emojis = [
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

  Future<(ui.Image, List<Rect>)> generate() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Draw background (transparent)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _atlasSize.toDouble(), _atlasSize.toDouble()),
      paint..color = Colors.transparent,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final rects = <Rect>[];
    const cols = _atlasSize ~/ _emojiSize;
    const rows = _atlasSize ~/ _emojiSize;

    final textStyle = kIsWeb
        ? GoogleFonts.notoColorEmoji(fontSize: 96)
        : const TextStyle(fontSize: 96);

    for (var i = 0; i < _emojis.length; i++) {
      if (i >= cols * rows) break;

      final col = i % cols;
      final row = i ~/ cols;
      final x = col * _emojiSize.toDouble();
      final y = row * _emojiSize.toDouble();

      final emoji = _emojis[i];
      textPainter
        ..text = TextSpan(
          text: emoji,
          style: textStyle,
        )
        ..layout(
          minWidth: _emojiSize.toDouble(),
          maxWidth: _emojiSize.toDouble(),
        );

      // Center the emoji in the cell
      final offset = Offset(
        x + (_emojiSize - textPainter.width) / 2,
        y + (_emojiSize - textPainter.height) / 2,
      );

      textPainter.paint(canvas, offset);
      rects.add(
        Rect.fromLTWH(x, y, _emojiSize.toDouble(), _emojiSize.toDouble()),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(_atlasSize, _atlasSize);

    return (image, rects);
  }
}
