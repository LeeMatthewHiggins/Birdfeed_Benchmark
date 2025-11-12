import 'package:benchmark/ecs/benchmark_world.dart';
import 'package:benchmark/services/fps_tracker.dart';
import 'package:benchmark/services/rive_benchmark_service.dart';
import 'package:benchmark/widgets/file_drop_zone.dart';
import 'package:benchmark/widgets/fps_graph_overlay.dart';
import 'package:benchmark/widgets/instance_count_slider.dart';
import 'package:benchmark/widgets/rive_particle_renderer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RiveBenchmarkTab extends StatefulWidget {
  const RiveBenchmarkTab({
    required this.fpsTracker,
    super.key,
  });

  final FpsTracker fpsTracker;

  @override
  State<RiveBenchmarkTab> createState() => _RiveBenchmarkTabState();
}

class _RiveBenchmarkTabState extends State<RiveBenchmarkTab> {
  final _riveService = RiveBenchmarkService();
  final _world = BenchmarkWorld();

  int _instanceCount = 100;
  String? _loadedFileName;
  late bool _useBatching;

  @override
  void initState() {
    super.initState();
    _useBatching = !kIsWeb;
    _riveService.initialize();
  }

  @override
  void dispose() {
    _world.dispose();
    _riveService.dispose();
    super.dispose();
  }

  Future<bool> _handleFileDropped(List<int> bytes, String fileName) async {
    final success = await _riveService.loadRiveFile(
      Uint8List.fromList(bytes),
      fileName,
    );

    if (success && mounted) {
      setState(() {
        _loadedFileName = fileName;
      });
      widget.fpsTracker.reset();
    }

    return success;
  }

  void _handleInstanceCountChanged(int count) {
    setState(() {
      _instanceCount = count;
    });
    widget.fpsTracker.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FileDropZone(
          onFileDropped: _handleFileDropped,
          allowedExtensions: const ['.riv'],
          fileName: _loadedFileName,
        ),
        const SizedBox(height: 16),
        InstanceCountSlider(
          instanceCount: _instanceCount,
          onChanged: _handleInstanceCountChanged,
        ),
        const SizedBox(height: 16),
        _buildBatchRenderingToggle(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildRenderArea(),
        ),
      ],
    );
  }

  Widget _buildBatchRenderingToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Use Batch Rendering',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message:
                'Enable to use batch rendering (faster on native, may not work on web). Disable to use individual rendering.',
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Switch(
            value: _useBatching,
            onChanged: (value) {
              setState(() {
                _useBatching = value;
              });
              widget.fpsTracker.reset();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRenderArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            if (_riveService.hasLoadedFile)
              RiveParticleRenderer(
                key: ValueKey(_loadedFileName),
                instanceCount: _instanceCount,
                world: _world,
                createRiveContent: _riveService.createRiveContent,
                useBatching: _useBatching,
                fpsTracker: widget.fpsTracker,
              )
            else
              const Center(
                child: Text(
                  'Drop a .riv file to begin',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 18,
                  ),
                ),
              ),
            FpsGraphOverlay(fpsTracker: widget.fpsTracker),
          ],
        ),
      ),
    );
  }
}
