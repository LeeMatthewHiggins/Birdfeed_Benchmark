import 'dart:collection';

class FpsTracker {
  FpsTracker({this.maxSamples = 120, this.smoothingSamples = 10});

  final int maxSamples;
  final int smoothingSamples;
  final Queue<double> _fpsSamples = Queue<double>();
  final Queue<double> _smoothingSamples = Queue<double>();

  double _currentFps = 0;

  double get currentFps => _currentFps;
  double get minFps {
    if (_fpsSamples.isEmpty) return 0;
    return _fpsSamples.reduce((a, b) => a < b ? a : b);
  }

  double get maxFps {
    if (_fpsSamples.isEmpty) return 0;
    return _fpsSamples.reduce((a, b) => a > b ? a : b);
  }

  double get averageFps {
    if (_fpsSamples.isEmpty) return 0;
    final sum = _fpsSamples.reduce((a, b) => a + b);
    return sum / _fpsSamples.length;
  }

  List<double> get fpsHistory => _fpsSamples.toList();

  void recordFrame(double deltaSeconds) {
    if (deltaSeconds <= 0) return;

    final instantFps = 1.0 / deltaSeconds;

    _fpsSamples.add(instantFps);
    if (_fpsSamples.length > maxSamples) {
      _fpsSamples.removeFirst();
    }

    _smoothingSamples.add(instantFps);
    if (_smoothingSamples.length > smoothingSamples) {
      _smoothingSamples.removeFirst();
    }

    if (_smoothingSamples.isNotEmpty) {
      final smoothSum = _smoothingSamples.reduce((a, b) => a + b);
      _currentFps = smoothSum / _smoothingSamples.length;
    } else {
      _currentFps = instantFps;
    }
  }

  void reset() {
    _fpsSamples.clear();
    _smoothingSamples.clear();
    _currentFps = 0;
  }

  void dispose() {
    _fpsSamples.clear();
    _smoothingSamples.clear();
  }
}
