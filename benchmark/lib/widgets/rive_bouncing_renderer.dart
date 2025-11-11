import 'package:flutter/material.dart';
import 'package:benchmark/services/rive_benchmark_service.dart';
import 'package:benchmark/widgets/checkerboard_background.dart';
import 'package:rive_native/rive_native.dart';

class RiveGridRenderer extends StatefulWidget {
  const RiveGridRenderer({
    required this.instanceCount,
    required this.createBouncingItem,
    super.key,
  });

  final int instanceCount;
  final BouncingItem? Function({
    required double boundsWidth,
    required double boundsHeight,
  }) createBouncingItem;

  @override
  State<RiveGridRenderer> createState() => _RiveGridRendererState();
}

class _RiveGridRendererState extends State<RiveGridRenderer> {
  late final RenderTexture _renderTexture;
  late final _RiveNativeRenderer _renderer;
  Size _lastSize = Size.zero;
  late final Stopwatch _stopwatch;
  int _lastElapsedMicroseconds = 0;

  @override
  void initState() {
    super.initState();
    _renderTexture = RiveNative.instance.makeRenderTexture();
    _stopwatch = Stopwatch()..start();
    _renderer = _RiveNativeRenderer(
      createBouncingItem: widget.createBouncingItem,
      instanceCount: widget.instanceCount,
      getDeltaTime: _getDeltaTime,
    );
  }

  double _getDeltaTime() {
    final currentMicroseconds = _stopwatch.elapsedMicroseconds;
    final deltaMicroseconds = currentMicroseconds - _lastElapsedMicroseconds;
    _lastElapsedMicroseconds = currentMicroseconds;

    if (deltaMicroseconds == 0) {
      return 0.016;
    }

    return (deltaMicroseconds / 1000000.0).clamp(0.0, 0.1);
  }

  @override
  void didUpdateWidget(RiveGridRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instanceCount != widget.instanceCount) {
      _renderer.updateInstanceCount(widget.instanceCount);
    }
  }

  @override
  void dispose() {
    _renderer.dispose();
    _renderTexture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final newSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (_lastSize != newSize) {
          _lastSize = newSize;
          _renderer.updateSize(newSize);
        }

        return Stack(
          children: [
            const CheckerboardBackground(),
            _renderTexture.widget(painter: _renderer),
          ],
        );
      },
    );
  }
}

final class _RiveNativeRenderer extends RenderTexturePainter {
  _RiveNativeRenderer({
    required this.createBouncingItem,
    required int instanceCount,
    required this.getDeltaTime,
  }) : _instanceCount = instanceCount;

  final BouncingItem? Function({
    required double boundsWidth,
    required double boundsHeight,
  }) createBouncingItem;
  final double Function() getDeltaTime;
  final List<BouncingItem> _bouncingItems = [];
  int _instanceCount;
  Size _size = Size.zero;

  static const double _instanceSize = 100;

  @override
  Color get background => Colors.transparent;

  void updateSize(Size size) {
    if (_size != size) {
      _size = size;
      _generateBouncingItems();
      notifyListeners();
    }
  }

  void updateInstanceCount(int count) {
    if (_instanceCount != count) {
      _instanceCount = count;
      _generateBouncingItems();
      notifyListeners();
    }
  }

  void _generateBouncingItems() {
    for (final item in _bouncingItems) {
      item.dispose();
    }
    _bouncingItems.clear();

    if (_size.width <= 0 || _size.height <= 0) {
      return;
    }

    for (var i = 0; i < _instanceCount; i++) {
      final item = createBouncingItem(
        boundsWidth: _size.width,
        boundsHeight: _size.height,
      );
      if (item != null) {
        _bouncingItems.add(item);
      }
    }
  }

  @override
  bool paint(
    RenderTexture texture,
    double devicePixelRatio,
    Size size,
    double elapsedSeconds,
  ) {
    if (_bouncingItems.isEmpty) {
      return false;
    }

    final deltaSeconds = getDeltaTime();

    for (final item in _bouncingItems) {
      item
        ..advance(deltaSeconds)
        ..updatePosition(deltaSeconds, size.width, size.height, _instanceSize);
    }

    final renderer = texture.renderer;

    for (final item in _bouncingItems) {
      final artboard = item.artboard;
      final x = item.position.x;
      final y = item.position.y;

      final artboardScale = _instanceSize / artboard.width;
      renderer
        ..save()
        ..translate(x, y)
        ..scale(artboardScale, artboardScale)
        ..translate(-artboard.width / 2, -artboard.height / 2);

      artboard.draw(renderer);
      renderer.restore();
    }

    return true;
  }

  @override
  void dispose() {
    for (final item in _bouncingItems) {
      item.dispose();
    }
    _bouncingItems.clear();
    super.dispose();
  }
}
