import 'dart:math';
import 'dart:typed_data';
import 'package:benchmark/ecs/components/rive_content_component.dart';
import 'package:rive/rive.dart';

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

  RiveContentComponent? createRiveContent() {
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
      final animationOffset = random.nextDouble() * _maxAnimationOffset;

      return RiveContentComponent(
        artboard: artboard,
        stateMachine: stateMachine,
        animationOffset: animationOffset,
      );
    } on Exception {
      return null;
    }
  }

  static const double _maxAnimationOffset = 5;

  void dispose() {
    _loadedFile?.dispose();
    _loadedFile = null;
    _loadedFileName = null;
  }
}
