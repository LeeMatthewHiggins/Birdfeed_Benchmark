import 'package:flutter/material.dart';

class CellSizeSlider extends StatelessWidget {
  const CellSizeSlider({
    required this.cellSize,
    required this.onChanged,
    super.key,
  });

  final int cellSize;
  final ValueChanged<int> onChanged;

  static const int _minCellSize = 32;
  static const int _maxCellSize = 128;
  static const List<int> _cellSizeValues = [
    32,
    64,
    128,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Cell Size:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              cellSize.toString(),
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
                value: _cellSizeValues.indexOf(cellSize).toDouble(),
                max: (_cellSizeValues.length - 1).toDouble(),
                divisions: _cellSizeValues.length - 1,
                onChanged: (value) => onChanged(_cellSizeValues[value.toInt()]),
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 80,
              child: Text(
                '($_minCellSize - $_maxCellSize)',
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
