import 'dart:collection';
import 'package:flutter/scheduler.dart';

class FpsTracker {
  FpsTracker({this.maxSamples = 120});

  final int maxSamples;
  final Queue<double> _fpsSamples = Queue<double>();

  Duration? _lastFrameTimestamp;
  FrameCallback? _frameCallback;

  double _currentFps = 0;
  double _minFps = double.infinity;
  double _maxFps = 0;

  bool _isTracking = false;

  double get currentFps => _currentFps;
  double get minFps => _minFps == double.infinity ? 0 : _minFps;
  double get maxFps => _maxFps;
  double get averageFps {
    if (_fpsSamples.isEmpty) return 0;
    final sum = _fpsSamples.reduce((a, b) => a + b);
    return sum / _fpsSamples.length;
  }

  List<double> get fpsHistory => _fpsSamples.toList();

  void start() {
    if (_isTracking) return;

    _isTracking = true;
    _lastFrameTimestamp = null;

    _frameCallback = (Duration timestamp) {
      _onFrame(timestamp);
      if (_isTracking) {
        SchedulerBinding.instance.scheduleFrameCallback(_frameCallback!);
      }
    };

    SchedulerBinding.instance.scheduleFrameCallback(_frameCallback!);
  }

  void _onFrame(Duration timestamp) {
    if (_lastFrameTimestamp != null) {
      final delta = timestamp - _lastFrameTimestamp!;
      final deltaSeconds = delta.inMicroseconds / 1000000.0;

      if (deltaSeconds > 0) {
        _currentFps = 1.0 / deltaSeconds;

        _fpsSamples.add(_currentFps);
        if (_fpsSamples.length > maxSamples) {
          _fpsSamples.removeFirst();
        }

        if (_currentFps < _minFps) _minFps = _currentFps;
        if (_currentFps > _maxFps) _maxFps = _currentFps;
      }
    }

    _lastFrameTimestamp = timestamp;
  }

  void reset() {
    _fpsSamples.clear();
    _minFps = double.infinity;
    _maxFps = 0;
    _currentFps = 0;
  }

  void stop() {
    _isTracking = false;
    _frameCallback = null;
  }

  void dispose() {
    stop();
    _fpsSamples.clear();
  }
}
