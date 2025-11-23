import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:synchronized/synchronized.dart';

class TextureBuffer {
  ui.Image? _textureA;
  ui.Image? _textureB;
  bool _useTextureA = true;
  final _lock = Lock();

  ui.Image? get current => _useTextureA ? _textureA : _textureB;

  void _swap(ui.Image newTexture) {
    if (_useTextureA) {
      _textureB?.dispose();
      _textureB = newTexture;
    } else {
      _textureA?.dispose();
      _textureA = newTexture;
    }
    _useTextureA = !_useTextureA;
  }

  Future<void> update(
    Uint8List pixels,
    int width,
    int height,
  ) async {
    await _lock.synchronized(() async {
      final image = await _decodeImage(pixels, width, height);
      _swap(image);
    });
  }

  Future<ui.Image> _decodeImage(
    Uint8List pixels,
    int width,
    int height,
  ) async {
    final descriptor = ui.ImageDescriptor.raw(
      await ui.ImmutableBuffer.fromUint8List(pixels),
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void dispose() {
    _textureA?.dispose();
    _textureB?.dispose();
    _textureA = null;
    _textureB = null;
  }
}
