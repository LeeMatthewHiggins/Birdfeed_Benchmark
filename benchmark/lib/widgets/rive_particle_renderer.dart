import 'package:benchmark/ecs/benchmark_world.dart';
import 'package:benchmark/ecs/components/rive_content_component.dart';
import 'package:benchmark/services/fps_tracker.dart';
import 'package:benchmark/widgets/checkerboard_background.dart';
import 'package:dentity/dentity.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:rive_native/rive_native.dart';

class RiveParticleRenderer extends StatefulWidget {
  const RiveParticleRenderer({
    required this.instanceCount,
    required this.world,
    required this.createRiveContent,
    required this.fpsTracker,
    this.useBatching = false,
    super.key,
  });

  final int instanceCount;
  final BenchmarkWorld world;
  final RiveContentComponent? Function() createRiveContent;
  final FpsTracker fpsTracker;
  final bool useBatching;

  @override
  State<RiveParticleRenderer> createState() => _RiveParticleRendererState();
}

class _RiveParticleRendererState extends State<RiveParticleRenderer> {
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
      world: widget.world,
      createRiveContent: widget.createRiveContent,
      instanceCount: widget.instanceCount,
      getDeltaTime: _getDeltaTime,
      useBatching: widget.useBatching,
      fpsTracker: widget.fpsTracker,
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
  void didUpdateWidget(RiveParticleRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instanceCount != widget.instanceCount) {
      _renderer.updateInstanceCount(widget.instanceCount);
    }
    if (oldWidget.useBatching != widget.useBatching) {
      _renderer.updateBatching(useBatching: widget.useBatching);
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
    required this.world,
    required this.createRiveContent,
    required int instanceCount,
    required this.getDeltaTime,
    required bool useBatching,
    required this.fpsTracker,
  })  : _instanceCount = instanceCount,
        _useBatching = useBatching;

  final BenchmarkWorld world;
  final RiveContentComponent? Function() createRiveContent;
  final double Function() getDeltaTime;
  final FpsTracker fpsTracker;
  final List<Entity> _entities = [];
  int _instanceCount;
  Size _size = Size.zero;

  static const double _instanceSize = 100;
  bool _useBatching;

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

  void updateBatching({required bool useBatching}) {
    if (_useBatching != useBatching) {
      _useBatching = useBatching;
      notifyListeners();
    }
  }

  void _generateBouncingItems() {
    for (final entity in _entities) {
      final content = world.getRiveContent(entity);
      content?.dispose();
      world.destroyEntity(entity);
    }
    _entities.clear();

    if (_size.width <= 0 || _size.height <= 0) {
      return;
    }

    for (var i = 0; i < _instanceCount; i++) {
      final content = createRiveContent();
      if (content != null) {
        final entity = world.createRiveEntity(
          content: content,
          boundsWidth: _size.width,
          boundsHeight: _size.height,
        );
        _entities.add(entity);
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
    if (_entities.isEmpty) {
      return false;
    }

    final deltaSeconds = getDeltaTime();
    final deltaMicroseconds = (deltaSeconds * 1000000).round();
    final delta = Duration(microseconds: deltaMicroseconds);

    fpsTracker.recordFrame(deltaSeconds);

    world.update(delta: delta);

    final renderer = texture.renderer..save();
    _batchAdvanceAndRender(renderer, deltaSeconds);
    renderer.restore();

    return true;
  }

  void _batchAdvanceAndRender(Renderer renderer, double deltaSeconds) {
    final stateMachines = <StateMachine>[];

    for (var i = 0; i < _entities.length; i++) {
      final entity = _entities[i];
      final position = world.getPosition(entity);
      final content = world.getRiveContent(entity);

      if (position == null || content == null) continue;

      final artboard = content.artboard;
      final artboardScale = _instanceSize / artboard.width;
      final bounds = artboard.bounds;
      final center = bounds.center();

      final offsetX = position.x - (center.x * artboardScale);
      final offsetY = position.y - (center.y * artboardScale);

      final transform = Mat2D.fromTranslate(offsetX, offsetY);
      transform[0] = artboardScale;
      transform[3] = artboardScale;

      artboard.renderTransform = transform;

      if (_useBatching && content.stateMachine != null) {
        stateMachines.add(content.stateMachine!);
      } else {
        renderer
          ..save()
          ..translate(offsetX, offsetY)
          ..scale(artboardScale, artboardScale);
        if (content.stateMachine != null) {
          content.stateMachine!.advanceAndApply(deltaSeconds);
        } else {
          artboard.advance(deltaSeconds);
        }
        artboard.draw(renderer);
        renderer.restore();
      }
    }

    if (stateMachines.isNotEmpty) {
      rive.Rive.batchAdvanceAndRender(stateMachines, deltaSeconds, renderer);
    }
  }

  @override
  void dispose() {
    for (final entity in _entities) {
      final content = world.getRiveContent(entity);
      content?.dispose();
      world.destroyEntity(entity);
    }
    _entities.clear();
    super.dispose();
  }
}
