import 'dart:ui' as ui;

import 'package:dentity/dentity.dart';

final class SpriteShaderContentComponent extends Component {
  SpriteShaderContentComponent({
    required this.image,
    required this.shader,
  });

  final ui.Image image;
  final ui.FragmentShader shader;

  @override
  SpriteShaderContentComponent clone() => SpriteShaderContentComponent(
        image: image,
        shader: shader,
      );

  @override
  int compareTo(dynamic other) {
    if (other is! SpriteShaderContentComponent) return -1;
    return 0;
  }

  void dispose() {}
}
