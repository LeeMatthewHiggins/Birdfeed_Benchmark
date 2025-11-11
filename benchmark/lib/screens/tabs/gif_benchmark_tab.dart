import 'dart:typed_data';

import 'package:benchmark/services/fps_tracker.dart';
import 'package:benchmark/services/gif_benchmark_service.dart';
import 'package:benchmark/widgets/file_drop_zone.dart';
import 'package:benchmark/widgets/fps_graph_overlay.dart';
import 'package:benchmark/widgets/gif_particle_renderer.dart';
import 'package:benchmark/widgets/instance_count_slider.dart';
import 'package:flutter/material.dart';

class GifBenchmarkTab extends StatefulWidget {
  const GifBenchmarkTab({
    required this.fpsTracker,
    super.key,
  });

  final FpsTracker fpsTracker;

  @override
  State<GifBenchmarkTab> createState() => _GifBenchmarkTabState();
}

class _GifBenchmarkTabState extends State<GifBenchmarkTab> {
  final _gifService = GifBenchmarkService();

  int _instanceCount = 100;
  String? _loadedFileName;

  @override
  void dispose() {
    _gifService.dispose();
    super.dispose();
  }

  Future<bool> _handleFileDropped(List<int> bytes, String fileName) async {
    final success = await _gifService.loadGifFile(
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
          allowedExtensions: const ['.gif'],
          fileName: _loadedFileName,
        ),
        const SizedBox(height: 16),
        InstanceCountSlider(
          instanceCount: _instanceCount,
          onChanged: _handleInstanceCountChanged,
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
            if (_gifService.hasLoadedFile)
              GifParticleRenderer(
                key: ValueKey(_loadedFileName),
                instanceCount: _instanceCount,
                createParticle: _gifService.createGifParticle,
              )
            else
              const Center(
                child: Text(
                  'Drop a .gif file to begin',
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
