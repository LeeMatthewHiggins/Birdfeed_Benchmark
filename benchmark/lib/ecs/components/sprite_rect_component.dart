import 'dart:ui';

import 'package:dentity/dentity.dart';

final class SpriteRectComponent extends Component {
  SpriteRectComponent({
    required this.sourceRect,
  });

  final Rect sourceRect;

  @override
  SpriteRectComponent clone() => SpriteRectComponent(
        sourceRect: sourceRect,
      );

  @override
  int compareTo(dynamic other) {
    if (other is! SpriteRectComponent) return -1;
    return 0;
  }
}
