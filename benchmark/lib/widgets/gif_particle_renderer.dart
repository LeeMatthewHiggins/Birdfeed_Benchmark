import 'package:flutter/material.dart';
import 'package:benchmark/models/simple_particle.dart';
import 'package:benchmark/services/gif_benchmark_service.dart';
import 'package:benchmark/widgets/checkerboard_background.dart';

class GifParticleRenderer extends StatefulWidget {
  const GifParticleRenderer({
    required this.instanceCount,
    required this.createParticle,
    super.key,
  });

  final int instanceCount;
  final SimpleParticle<GifInstance>? Function({
    required double boundsWidth,
    required double boundsHeight,
  }) createParticle;

  @override
  State<GifParticleRenderer> createState() => _GifParticleRendererState();
}

class _GifParticleRendererState extends State<GifParticleRenderer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final List<SimpleParticle<GifInstance>> _particles = [];
  Size _lastSize = Size.zero;

  static const Duration _frameDuration = Duration(milliseconds: 16);
  static const double _instanceSize = 100;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _frameDuration,
    )..repeat();

    _animationController.addListener(_updateInstances);
  }

  @override
  void didUpdateWidget(GifParticleRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instanceCount != widget.instanceCount) {
      _generateParticles();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particles.clear();
    super.dispose();
  }

  void _updateInstances() {
    final deltaSeconds = _frameDuration.inMicroseconds / 1000000.0;
    for (final particle in _particles) {
      particle.content.advance(deltaSeconds);
      particle.updatePosition(
        deltaSeconds,
        _lastSize.width,
        _lastSize.height,
        _instanceSize,
      );
    }
  }

  void _generateParticles() {
    _particles.clear();

    if (_lastSize.width <= 0 || _lastSize.height <= 0) {
      return;
    }

    for (var i = 0; i < widget.instanceCount; i++) {
      final particle = widget.createParticle(
        boundsWidth: _lastSize.width,
        boundsHeight: _lastSize.height,
      );
      if (particle != null) {
        _particles.add(particle);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final newSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (_lastSize != newSize) {
          _lastSize = newSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _generateParticles();
          });
        }

        if (_particles.isEmpty) {
          return const Center(
            child: Text(
              'No GIF file loaded',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          );
        }

        return Stack(
          children: [
            const CheckerboardBackground(),
            RepaintBoundary(
              child: CustomPaint(
                painter: _GifParticlePainter(
                  particles: _particles,
                  instanceSize: _instanceSize,
                  repaint: _animationController,
                ),
                child: Container(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GifParticlePainter extends CustomPainter {
  _GifParticlePainter({
    required this.particles,
    required this.instanceSize,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<SimpleParticle<GifInstance>> particles;
  final double instanceSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) {
      return;
    }

    final paint = Paint();

    for (final particle in particles) {
      final gifInstance = particle.content;
      final x = particle.position.x;
      final y = particle.position.y;

      final currentFrame = gifInstance.currentFrame;

      final srcWidth = currentFrame.width.toDouble();
      final srcHeight = currentFrame.height.toDouble();
      final scale = instanceSize / srcWidth;

      canvas
        ..save()
        ..translate(x, y)
        ..scale(scale, scale)
        ..translate(-srcWidth / 2, -srcHeight / 2)
        ..drawImage(currentFrame, Offset.zero, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_GifParticlePainter oldDelegate) => true;
}
