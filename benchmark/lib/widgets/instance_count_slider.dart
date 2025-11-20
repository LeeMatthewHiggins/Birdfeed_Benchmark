import 'package:flutter/material.dart';

class InstanceCountSlider extends StatefulWidget {
  const InstanceCountSlider({
    required this.instanceCount,
    required this.onChanged,
    super.key,
  });

  final int instanceCount;
  final ValueChanged<int> onChanged;

  @override
  State<InstanceCountSlider> createState() => _InstanceCountSliderState();
}

class _InstanceCountSliderState extends State<InstanceCountSlider> {
  static const int _minInstances = 1;
  static const int _maxInstances = 50000;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.instanceCount.toDouble();
  }

  @override
  void didUpdateWidget(InstanceCountSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instanceCount != widget.instanceCount) {
      _currentValue = widget.instanceCount.toDouble();
    }
  }

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
              _currentValue.toInt().toString(),
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
                value: _currentValue,
                min: _minInstances.toDouble(),
                max: _maxInstances.toDouble(),
                divisions: 100,
                onChanged: (value) {
                  setState(() {
                    _currentValue = value;
                  });
                },
                onChangeEnd: (value) {
                  widget.onChanged(value.toInt());
                },
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
