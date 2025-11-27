import 'dart:ui';

import 'package:dentity/dentity.dart';

final class SpriteRectComponent extends Component {
  SpriteRectComponent({
    required this.sourceRect,
    this.rotated = false,
  });

  final Rect sourceRect;
  final bool rotated;

  @override
  SpriteRectComponent clone() => SpriteRectComponent(
        sourceRect: sourceRect,
        rotated: rotated,
      );

  @override
  int compareTo(dynamic other) {
    if (other is! SpriteRectComponent) return -1;
    return 0;
  }
}
