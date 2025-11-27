import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:megasprite/src/models/trim_rect.dart';

class TrimResult {
  const TrimResult({
    required this.trimmedPixels,
    required this.trimRect,
    required this.pixelHash,
  });

  final Uint8List trimmedPixels;
  final TrimRect trimRect;
  final int pixelHash;
}

class ImageTrimmer {
  const ImageTrimmer._();

  static const int _bytesPerPixel = 4;
  static const int _alphaOffset = 3;
  static const int _defaultAlphaThreshold = 0;

  static Future<TrimResult> trim(
    ui.Image image, {
    int alphaThreshold = _defaultAlphaThreshold,
  }) async {
    final width = image.width;
    final height = image.height;

    final byteData = await image.toByteData();
    if (byteData == null) {
      return TrimResult(
        trimmedPixels: Uint8List(0),
        trimRect: const TrimRect.empty(),
        pixelHash: 0,
      );
    }

    final pixels = byteData.buffer.asUint8List();
    final bounds = _findBounds(pixels, width, height, alphaThreshold);

    if (bounds == null) {
      return TrimResult(
        trimmedPixels: Uint8List(0),
        trimRect: TrimRect(
          originalWidth: width,
          originalHeight: height,
          x: 0,
          y: 0,
          width: 0,
          height: 0,
        ),
        pixelHash: 0,
      );
    }

    final trimmedPixels = _extractTrimmedPixels(
      pixels,
      width,
      bounds.minX,
      bounds.minY,
      bounds.width,
      bounds.height,
    );

    final pixelHash = _computeHash(trimmedPixels);

    return TrimResult(
      trimmedPixels: trimmedPixels,
      trimRect: TrimRect(
        originalWidth: width,
        originalHeight: height,
        x: bounds.minX,
        y: bounds.minY,
        width: bounds.width,
        height: bounds.height,
      ),
      pixelHash: pixelHash,
    );
  }

  static _Bounds? _findBounds(
    Uint8List pixels,
    int width,
    int height,
    int alphaThreshold,
  ) {
    var minX = width;
    var maxX = -1;
    var minY = height;
    var maxY = -1;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = (y * width + x) * _bytesPerPixel + _alphaOffset;
        if (pixels[index] > alphaThreshold) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      return null;
    }

    return _Bounds(
      minX: minX,
      minY: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1,
    );
  }

  static Uint8List _extractTrimmedPixels(
    Uint8List sourcePixels,
    int sourceWidth,
    int trimX,
    int trimY,
    int trimWidth,
    int trimHeight,
  ) {
    final trimmedPixels = Uint8List(trimWidth * trimHeight * _bytesPerPixel);

    for (var y = 0; y < trimHeight; y++) {
      final srcRowStart =
          ((trimY + y) * sourceWidth + trimX) * _bytesPerPixel;
      final dstRowStart = y * trimWidth * _bytesPerPixel;
      final rowBytes = trimWidth * _bytesPerPixel;

      trimmedPixels.setRange(
        dstRowStart,
        dstRowStart + rowBytes,
        sourcePixels,
        srcRowStart,
      );
    }

    return trimmedPixels;
  }

  static int _computeHash(Uint8List pixels) {
    var hash = 0;
    for (var i = 0; i < pixels.length; i++) {
      hash = (hash * 31 + pixels[i]) & 0x7FFFFFFF;
    }
    return hash;
  }

  static Future<ui.Image> createImageFromPixels(
    Uint8List pixels,
    int width,
    int height,
  ) async {
    final completer = ui.ImmutableBuffer.fromUint8List(pixels);
    final buffer = await completer;
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<ui.Image> createRotatedImage(
    Uint8List pixels,
    int width,
    int height,
  ) async {
    final rotatedPixels = Uint8List(width * height * _bytesPerPixel);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final srcIndex = (y * width + x) * _bytesPerPixel;
        final dstX = height - 1 - y;
        final dstY = x;
        final dstIndex = (dstY * height + dstX) * _bytesPerPixel;

        rotatedPixels[dstIndex] = pixels[srcIndex];
        rotatedPixels[dstIndex + 1] = pixels[srcIndex + 1];
        rotatedPixels[dstIndex + 2] = pixels[srcIndex + 2];
        rotatedPixels[dstIndex + 3] = pixels[srcIndex + 3];
      }
    }

    return createImageFromPixels(rotatedPixels, height, width);
  }
}

class _Bounds {
  const _Bounds({
    required this.minX,
    required this.minY,
    required this.width,
    required this.height,
  });

  final int minX;
  final int minY;
  final int width;
  final int height;
}
