import 'dart:typed_data';

import 'package:benchmark/ecs/benchmark_world.dart';
import 'package:benchmark/services/fps_tracker.dart';
import 'package:benchmark/services/sprite_shader_benchmark_service.dart';
import 'package:benchmark/widgets/cell_size_slider.dart';
import 'package:benchmark/widgets/file_drop_zone.dart';
import 'package:benchmark/widgets/fps_graph_overlay.dart';
import 'package:benchmark/widgets/instance_count_slider.dart';
import 'package:benchmark/widgets/sprite_shader_renderer.dart';
import 'package:benchmark/widgets/sprite_size_slider.dart';
import 'package:flutter/material.dart';

class SpriteShaderBenchmarkTab extends StatefulWidget {
  const SpriteShaderBenchmarkTab({
    required this.fpsTracker,
    super.key,
  });

  final FpsTracker fpsTracker;

  @override
  State<SpriteShaderBenchmarkTab> createState() =>
      _SpriteShaderBenchmarkTabState();
}

class _SpriteShaderBenchmarkTabState extends State<SpriteShaderBenchmarkTab> {
  final _spriteShaderService = SpriteShaderBenchmarkService();
  final _world = BenchmarkWorld();

  int _instanceCount = 100;
  int _cellSize = 128;
  int _spriteSize = 100;
  bool _showDebugOverlay = false;
  String? _loadedFileName;

  @override
  void dispose() {
    _world.dispose();
    _spriteShaderService.dispose();
    super.dispose();
  }

  Future<bool> _handleFileDropped(List<int> bytes, String fileName) async {
    final success = await _spriteShaderService.loadImageFile(
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

  void _handleCellSizeChanged(int size) {
    setState(() {
      _cellSize = size;
    });
    widget.fpsTracker.reset();
  }

  void _handleSpriteSizeChanged(int size) {
    setState(() {
      _spriteSize = size;
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
          allowedExtensions: const [
            '.png',
            '.jpg',
            '.jpeg',
            '.webp',
            '.gif',
            '.bmp',
            '.wbmp',
          ],
          fileName: _loadedFileName,
        ),
        const SizedBox(height: 16),
        InstanceCountSlider(
          instanceCount: _instanceCount,
          onChanged: _handleInstanceCountChanged,
        ),
        const SizedBox(height: 16),
        CellSizeSlider(
          cellSize: _cellSize,
          onChanged: _handleCellSizeChanged,
        ),
        const SizedBox(height: 16),
        SpriteSizeSlider(
          spriteSize: _spriteSize,
          onChanged: _handleSpriteSizeChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'Debug Overlay:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: _showDebugOverlay,
              onChanged: (value) {
                setState(() {
                  _showDebugOverlay = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildRenderArea(),
        ),
      ],
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
            if (_spriteShaderService.hasLoadedFile)
              SpriteShaderRenderer(
                key: ValueKey(_loadedFileName),
                instanceCount: _instanceCount,
                world: _world,
                createSpriteShaderContent:
                    _spriteShaderService.createSpriteShaderContent,
                fpsTracker: widget.fpsTracker,
                cellSize: _cellSize,
                showDebugOverlay: _showDebugOverlay,
                spriteSize: _spriteSize,
              )
            else
              const Center(
                child: Text(
                  'Drop an image file to begin',
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
