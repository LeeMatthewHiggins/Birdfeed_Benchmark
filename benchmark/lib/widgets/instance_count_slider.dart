import 'package:flutter/material.dart';

class InstanceCountSlider extends StatelessWidget {
  const InstanceCountSlider({
    required this.instanceCount,
    required this.onChanged,
    super.key,
  });

  final int instanceCount;
  final ValueChanged<int> onChanged;

  static const int _minInstances = 1;
  static const int _maxInstances = 5000;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Instances:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              instanceCount.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: instanceCount.toDouble(),
                min: _minInstances.toDouble(),
                max: _maxInstances.toDouble(),
                divisions: 100,
                onChanged: (value) => onChanged(value.toInt()),
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 80,
              child: Text(
                '($_minInstances - $_maxInstances)',
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
