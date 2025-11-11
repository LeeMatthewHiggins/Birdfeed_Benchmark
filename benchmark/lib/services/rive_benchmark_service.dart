import 'dart:math';
import 'dart:typed_data';
import 'package:rive/rive.dart';

class BouncingItem {
  BouncingItem({
    required this.artboard,
    required this.stateMachine,
    required double x,
    required double y,
    required double velocityX,
    required double velocityY,
    required this.animationOffset,
  })  : position = ArtboardPosition(x, y),
        velocity = ArtboardVelocity(velocityX, velocityY);

  final Artboard artboard;
  final StateMachine? stateMachine;
  final ArtboardPosition position;
  final ArtboardVelocity velocity;
  final double animationOffset;

  bool _offsetApplied = false;

  void advance(double seconds) {
    if (!_offsetApplied) {
      if (stateMachine != null) {
        stateMachine!.advanceAndApply(animationOffset);
      } else {
        artboard.advance(animationOffset);
      }
      _offsetApplied = true;
    }

    if (stateMachine != null) {
      stateMachine!.advanceAndApply(seconds);
    } else {
      artboard.advance(seconds);
    }
  }

  void updatePosition(
    double deltaSeconds,
    double boundsWidth,
    double boundsHeight,
    double instanceSize,
  ) {
    position.x += velocity.x * deltaSeconds;
    position.y += velocity.y * deltaSeconds;

    final halfSize = instanceSize / 2;

    if (position.x - halfSize <= 0) {
      position.x = halfSize;
      velocity.x = velocity.x.abs();
    } else if (position.x + halfSize >= boundsWidth) {
      position.x = boundsWidth - halfSize;
      velocity.x = -velocity.x.abs();
    }

    if (position.y - halfSize <= 0) {
      position.y = halfSize;
      velocity.y = velocity.y.abs();
    } else if (position.y + halfSize >= boundsHeight) {
      position.y = boundsHeight - halfSize;
      velocity.y = -velocity.y.abs();
    }
  }

  void dispose() {
    stateMachine?.dispose();
    artboard.dispose();
  }
}

class ArtboardPosition {
  ArtboardPosition(this.x, this.y);
  double x;
  double y;
}

class ArtboardVelocity {
  ArtboardVelocity(this.x, this.y);
  double x;
  double y;
}

class RiveBenchmarkService {
  factory RiveBenchmarkService() => _instance;

  RiveBenchmarkService._internal();
  static final RiveBenchmarkService _instance =
      RiveBenchmarkService._internal();

  File? _loadedFile;
  String? _loadedFileName;
  late Factory _riveFactory;
  bool _initialized = false;

  bool get initialized => _initialized;
  bool get hasLoadedFile => _loadedFile != null;
  String? get loadedFileName => _loadedFileName;

  Future<void> initialize() async {
    if (_initialized) return;
    await RiveNative.init();
    _riveFactory = Factory.rive;
    _initialized = true;
  }

  Future<bool> loadRiveFile(Uint8List bytes, String fileName) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      _loadedFile = await File.decode(bytes, riveFactory: _riveFactory);
      _loadedFileName = fileName;
      return _loadedFile != null;
    } on Exception {
      _loadedFile = null;
      _loadedFileName = null;
      return false;
    }
  }

  BouncingItem? createBouncingItem({
    required double boundsWidth,
    required double boundsHeight,
  }) {
    if (_loadedFile == null) {
      return null;
    }

    try {
      final artboard = _loadedFile!.defaultArtboard();
      if (artboard == null) {
        return null;
      }

      final stateMachine = artboard.defaultStateMachine();

      final random = Random();
      final x = random.nextDouble() * boundsWidth;
      final y = random.nextDouble() * boundsHeight;
      final velocityX =
          (_minVelocity + random.nextDouble() * (_maxVelocity - _minVelocity)) *
              (random.nextBool() ? 1 : -1);
      final velocityY =
          (_minVelocity + random.nextDouble() * (_maxVelocity - _minVelocity)) *
              (random.nextBool() ? 1 : -1);
      final animationOffset = random.nextDouble() * _maxAnimationOffset;

      return BouncingItem(
        artboard: artboard,
        stateMachine: stateMachine,
        x: x,
        y: y,
        velocityX: velocityX,
        velocityY: velocityY,
        animationOffset: animationOffset,
      );
    } on Exception {
      return null;
    }
  }

  static const double _minVelocity = 50;
  static const double _maxVelocity = 200;
  static const double _maxAnimationOffset = 5;

  void dispose() {
    _loadedFile?.dispose();
    _loadedFile = null;
    _loadedFileName = null;
  }
}
