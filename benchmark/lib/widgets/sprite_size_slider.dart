import 'package:flutter/material.dart';

class SpriteSizeSlider extends StatelessWidget {
  const SpriteSizeSlider({
    required this.spriteSize,
    required this.onChanged,
    super.key,
  });

  final int spriteSize;
  final ValueChanged<int> onChanged;

  static const int _minSpriteSize = 16;
  static const int _maxSpriteSize = 256;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Sprite Size:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              spriteSize.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: spriteSize.toDouble(),
                min: _minSpriteSize.toDouble(),
                max: _maxSpriteSize.toDouble(),
                divisions: (_maxSpriteSize - _minSpriteSize) ~/ 16,
                onChanged: (value) => onChanged(value ~/ 16 * 16),
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 80,
              child: Text(
                '($_minSpriteSize - $_maxSpriteSize)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
