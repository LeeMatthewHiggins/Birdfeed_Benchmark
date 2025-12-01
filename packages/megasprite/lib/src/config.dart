class MegaSpriteConfig {
  const MegaSpriteConfig._();

  static const int maxSpritesPerCell = 255;
  static const int maxSpriteSize = 256;
  static const int signedByteOffset = 128;
  static const int pixelsPerSprite = 3;
  static const int maxAtlasDimension = 8191;
  static const int atlasDimensionBits = 13;
  static const int rotationBitMask = 0x20;
  static const int flipXBitMask = 0x40;
  static const int flipYBitMask = 0x80;
  static const int effectBitShift = 5;
  static const int effectBitMask = 0xE0;
}
