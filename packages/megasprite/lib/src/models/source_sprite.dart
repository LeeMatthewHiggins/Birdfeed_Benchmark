import 'dart:typed_data';

class SourceSprite {
  const SourceSprite({
    required this.identifier,
    required this.imageBytes,
  });

  final String identifier;
  final Uint8List imageBytes;
}
