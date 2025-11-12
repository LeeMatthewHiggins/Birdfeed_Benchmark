import 'dart:ui' as ui;

import 'package:dentity/dentity.dart';

final class GifContentComponent extends Component {
  GifContentComponent({
    required this.frames,
    required this.frameDurations,
  });

  final List<ui.Image> frames;
  final List<int> frameDurations;

  @override
  GifContentComponent clone() => GifContentComponent(
        frames: frames,
        frameDurations: frameDurations,
      );

  @override
  int compareTo(dynamic other) {
    if (other is! GifContentComponent) return -1;
    return frames.length.compareTo(other.frames.length);
  }

  void dispose() {}
}
