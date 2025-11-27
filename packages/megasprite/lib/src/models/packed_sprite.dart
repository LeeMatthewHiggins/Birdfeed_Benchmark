import 'package:megasprite/src/models/sprite_frame.dart';

class PackedSprite {
  const PackedSprite({
    required this.frame,
    required this.x,
    required this.y,
    required this.rotated,
    required this.pageIndex,
  });

  final SpriteFrame frame;
  final int x;
  final int y;
  final bool rotated;
  final int pageIndex;

  int get packedWidth => rotated ? frame.height : frame.width;
  int get packedHeight => rotated ? frame.width : frame.height;

  String get identifier => frame.identifier;
}

class SpriteAlias {
  const SpriteAlias({
    required this.identifier,
    required this.packedSprite,
  });

  final String identifier;
  final PackedSprite packedSprite;
}
