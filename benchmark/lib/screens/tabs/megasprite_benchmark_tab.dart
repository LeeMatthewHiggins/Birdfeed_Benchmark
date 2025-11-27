import 'dart:typed_data';

import 'package:benchmark/ecs/benchmark_world.dart';
import 'package:benchmark/services/fps_tracker.dart';
import 'package:benchmark/services/sprite_shader_benchmark_service.dart';
import 'package:benchmark/widgets/cell_size_slider.dart';
import 'package:benchmark/widgets/file_drop_zone.dart';
import 'package:benchmark/widgets/fps_graph_overlay.dart';
import 'package:benchmark/widgets/instance_count_slider.dart';
import 'package:benchmark/widgets/megasprite_renderer.dart';
import 'package:flutter/material.dart';
import 'package:megasprite/megasprite.dart';

class MegaSpriteBenchmarkTab extends StatefulWidget {
  const MegaSpriteBenchmarkTab({
    required this.fpsTracker,
    super.key,
  });

  final FpsTracker fpsTracker;

  @override
  State<MegaSpriteBenchmarkTab> createState() => _MegaSpriteBenchmarkTabState();
}

class _MegaSpriteBenchmarkTabState extends State<MegaSpriteBenchmarkTab> {
  final _spriteShaderService = SpriteShaderBenchmarkService();
  final _world = BenchmarkWorld();

  int _instanceCount = 100;
  int _cellSize = 32;
  bool _showDebugOverlay = false;
  String? _loadedFileName;
  bool _isGenerating = false;
  AtlasBuildProgress? _buildProgress;
  MegaSpritePainterType _painterType = MegaSpritePainterType.shader;

  @override
  void dispose() {
    _world.dispose();
    super.dispose();
  }

  Future<bool> _handleFileDropped(List<int> bytes, String fileName) async {
    final success = await _spriteShaderService.loadFile(
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

  Future<void> _handleGenerateEmojiAtlas() async {
    setState(() {
      _isGenerating = true;
      _buildProgress = null;
    });

    try {
      await for (final progress
          in _spriteShaderService.generateEmojiAtlas()) {
        if (mounted) {
          setState(() {
            _buildProgress = progress;
          });
        }
      }

      if (mounted) {
        setState(() {
          _loadedFileName = _spriteShaderService.loadedFileName;
          _isGenerating = false;
          _buildProgress = null;
        });
        widget.fpsTracker.reset();
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _buildProgress = null;
        });
      }
    }
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

  void _handlePainterTypeChanged(MegaSpritePainterType? type) {
    if (type == null) return;
    setState(() {
      _painterType = type;
    });
    widget.fpsTracker.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FileDropZone(
                onFileDropped: _handleFileDropped,
                allowedExtensions: const [
                  '.png',
                  '.jpg',
                  '.jpeg',
                  '.webp',
                  '.gif',
                  '.bmp',
                  '.wbmp',
                  '.zip',
                ],
                fileName: _loadedFileName,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _handleGenerateEmojiAtlas,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.emoji_emotions),
              label: Text(
                _isGenerating
                    ? _buildProgress?.message ?? 'Building...'
                    : 'Generate Emoji Atlas',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InstanceCountSlider(
                instanceCount: _instanceCount,
                onChanged: _handleInstanceCountChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _RenderTypeSelector(
              painterType: _painterType,
              onChanged: _handlePainterTypeChanged,
            ),
            const SizedBox(width: 24),
            if (_painterType == MegaSpritePainterType.shader) ...[
              Expanded(
                child: CellSizeSlider(
                  cellSize: _cellSize,
                  onChanged: _handleCellSizeChanged,
                ),
              ),
              const SizedBox(width: 24),
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
              MegaSpriteRenderer(
                key: ValueKey('$_loadedFileName-$_painterType'),
                instanceCount: _instanceCount,
                world: _world,
                atlas: _spriteShaderService.atlas,
                shader: _spriteShaderService.shader,
                fpsTracker: widget.fpsTracker,
                cellSize: _cellSize,
                showDebugOverlay: _showDebugOverlay,
                spriteSize: 64,
                painterType: _painterType,
                spriteLocations: _spriteShaderService.spriteLocations,
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

class _RenderTypeSelector extends StatelessWidget {
  const _RenderTypeSelector({
    required this.painterType,
    required this.onChanged,
  });

  final MegaSpritePainterType painterType;
  final ValueChanged<MegaSpritePainterType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Render Type:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        SegmentedButton<MegaSpritePainterType>(
          segments: const [
            ButtonSegment(
              value: MegaSpritePainterType.shader,
              label: Text('Shader'),
              icon: Icon(Icons.auto_awesome),
            ),
            ButtonSegment(
              value: MegaSpritePainterType.atlas,
              label: Text('Atlas'),
              icon: Icon(Icons.grid_view),
            ),
          ],
          selected: {painterType},
          onSelectionChanged: (selected) => onChanged(selected.first),
        ),
      ],
    );
  }
}
