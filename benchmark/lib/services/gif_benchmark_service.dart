import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:benchmark/models/simple_particle.dart';

class GifInstance {
  GifInstance(this.frames, this.frameDurations);

  final List<ui.Image> frames;
  final List<int> frameDurations;
  int currentFrameIndex = 0;
  double elapsedTime = 0;

  void advance(double seconds) {
    elapsedTime += seconds * 1000;

    while (elapsedTime >= frameDurations[currentFrameIndex]) {
      elapsedTime -= frameDurations[currentFrameIndex];
      currentFrameIndex = (currentFrameIndex + 1) % frames.length;
    }
  }

  ui.Image get currentFrame => frames[currentFrameIndex];

  void dispose() {}
}

class GifBenchmarkService {
  factory GifBenchmarkService() => _instance;

  GifBenchmarkService._internal();
  static final GifBenchmarkService _instance = GifBenchmarkService._internal();

  List<ui.Image>? _frames;
  List<int>? _frameDurations;
  String? _loadedFileName;

  bool get hasLoadedFile => _frames != null && _frames!.isNotEmpty;
  String? get loadedFileName => _loadedFileName;

  Future<bool> loadGifFile(Uint8List bytes, String fileName) async {
    try {
      final decoder = img.GifDecoder();
      final animation = decoder.decode(bytes);

      if (animation == null || animation.numFrames == 0) {
        _frames = null;
        _frameDurations = null;
        _loadedFileName = null;
        return false;
      }

      final frames = <ui.Image>[];
      final durations = <int>[];

      for (var i = 0; i < animation.numFrames; i++) {
        final frame = animation.getFrame(i);
        final duration = frame.frameDuration;

        final rgbaBytes = frame.convert(numChannels: 4).getBytes();
        final completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          rgbaBytes,
          frame.width,
          frame.height,
          ui.PixelFormat.rgba8888,
          completer.complete,
        );

        final image = await completer.future;
        frames.add(image);
        durations.add(duration);
      }

      _frames = frames;
      _frameDurations = durations;
      _loadedFileName = fileName;
      return true;
    } on Exception {
      _frames = null;
      _frameDurations = null;
      _loadedFileName = null;
      return false;
    }
  }

  SimpleParticle<GifInstance>? createGifParticle({
    required double boundsWidth,
    required double boundsHeight,
  }) {
    if (_frames == null || _frames!.isEmpty || _frameDurations == null) {
      return null;
    }

    final gifInstance = GifInstance(_frames!, _frameDurations!);

    return SimpleParticle.createRandom(
      content: gifInstance,
      boundsWidth: boundsWidth,
      boundsHeight: boundsHeight,
    );
  }

  void dispose() {
    if (_frames != null) {
      for (final frame in _frames!) {
        frame.dispose();
      }
    }
    _frames = null;
    _frameDurations = null;
    _loadedFileName = null;
  }
}
