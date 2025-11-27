import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atlas_creator/controllers/atlas_selection_controller.dart';
import 'package:atlas_creator/screens/atlas_creator_screen.dart';
import 'package:flutter/material.dart';
import 'package:megasprite/megasprite.dart';

class SpriteInfoPanel extends StatefulWidget {
  const SpriteInfoPanel({
    required this.sprites,
    required this.selectionController,
    required this.result,
    required this.atlasSizePreset,
    required this.onClose,
    super.key,
  });

  final List<SpriteEntry> sprites;
  final AtlasSelectionController selectionController;
  final AtlasResult? result;
  final AtlasSizePreset atlasSizePreset;
  final VoidCallback onClose;

  @override
  State<SpriteInfoPanel> createState() => _SpriteInfoPanelState();
}

class _SpriteInfoPanelState extends State<SpriteInfoPanel> {
  ui.Image? _previewImage;
  int? _imageWidth;
  int? _imageHeight;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.selectionController.addListener(_onSelectionChanged);
    _loadSelectedImage();
  }

  @override
  void didUpdateWidget(SpriteInfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectionController != widget.selectionController) {
      oldWidget.selectionController.removeListener(_onSelectionChanged);
      widget.selectionController.addListener(_onSelectionChanged);
    }
    if (oldWidget.sprites != widget.sprites) {
      _loadSelectedImage();
    }
  }

  @override
  void dispose() {
    widget.selectionController.removeListener(_onSelectionChanged);
    _previewImage?.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    _loadSelectedImage();
  }

  Future<void> _loadSelectedImage() async {
    final selectedId = widget.selectionController.selectedSpriteId;
    if (selectedId == null) {
      setState(() {
        _previewImage?.dispose();
        _previewImage = null;
        _imageWidth = null;
        _imageHeight = null;
      });
      return;
    }

    final entry = widget.sprites.where((s) => s.identifier == selectedId).firstOrNull;
    if (entry == null) {
      setState(() {
        _previewImage?.dispose();
        _previewImage = null;
        _imageWidth = null;
        _imageHeight = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final image = await _decodeImage(entry.bytes);
      _previewImage?.dispose();
      setState(() {
        _previewImage = image;
        _imageWidth = image.width;
        _imageHeight = image.height;
        _isLoading = false;
      });
    } on Exception {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  PackedSprite? _findPackedSprite(String identifier) {
    final result = widget.result;
    if (result == null) return null;

    for (final page in result.pages) {
      for (final packed in page.packedSprites) {
        if (packed.identifier == identifier) {
          return packed;
        }
      }
      for (final alias in page.aliases) {
        if (alias.identifier == identifier) {
          return alias.packedSprite;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.selectionController.selectedSpriteId;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (selectedId == null) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final width = _imageWidth;
    final height = _imageHeight;

    if (width == null || height == null) {
      return const Center(child: Text('Failed to load image'));
    }

    final ramBytes = width * height * 4;
    final ramKb = ramBytes / 1024;
    final ramMb = ramKb / 1024;

    final atlasArea = widget.atlasSizePreset.dimension * widget.atlasSizePreset.dimension;
    final spriteArea = width * height;
    final atlasPercent = (spriteArea / atlasArea) * 100;

    final packedSprite = _findPackedSprite(selectedId);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Sprite Info',
                  style: textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: widget.onClose,
                tooltip: 'Close',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedId,
                  style: textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                if (_previewImage != null)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: _CheckerboardBackground(
                        child: Center(
                          child: RawImage(
                            image: _previewImage,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _InfoSection(
                  title: 'Dimensions',
                  children: [
                    _InfoRow(label: 'Width', value: '$width px'),
                    _InfoRow(label: 'Height', value: '$height px'),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoSection(
                  title: 'Memory',
                  children: [
                    _InfoRow(
                      label: 'RAM Size',
                      value: ramMb >= 1
                          ? '${ramMb.toStringAsFixed(2)} MB'
                          : '${ramKb.toStringAsFixed(1)} KB',
                    ),
                    _InfoRow(label: 'Bytes', value: _formatBytes(ramBytes)),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoSection(
                  title: 'Atlas Usage',
                  children: [
                    _InfoRow(
                      label: 'Page Size',
                      value: '${widget.atlasSizePreset.dimension}x${widget.atlasSizePreset.dimension}',
                    ),
                    _InfoRow(
                      label: 'Coverage',
                      value: '${atlasPercent.toStringAsFixed(2)}%',
                    ),
                  ],
                ),
                if (packedSprite != null) ...[
                  const SizedBox(height: 12),
                  _InfoSection(
                    title: 'Packed Info',
                    children: [
                      _InfoRow(
                        label: 'Position',
                        value: '(${packedSprite.x}, ${packedSprite.y})',
                      ),
                      _InfoRow(
                        label: 'Packed Size',
                        value: '${packedSprite.packedWidth}x${packedSprite.packedHeight}',
                      ),
                      _InfoRow(
                        label: 'Rotated',
                        value: packedSprite.rotated ? 'Yes' : 'No',
                      ),
                      if (packedSprite.frame.trimRect.isTrimmed) ...[
                        const _InfoRow(
                          label: 'Trimmed',
                          value: 'Yes',
                        ),
                        _InfoRow(
                          label: 'Trimmed Size',
                          value: '${packedSprite.frame.trimRect.width}x${packedSprite.frame.trimRect.height}',
                        ),
                        _InfoRow(
                          label: 'Trim Offset',
                          value: '(${packedSprite.frame.trimRect.offsetX}, ${packedSprite.frame.trimRect.offsetY})',
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    return bytes.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckerboardBackground extends StatelessWidget {
  const _CheckerboardBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CheckerboardPainter(),
      child: child,
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  static const _squareSize = 8.0;
  static const _lightColor = Color(0xFFE0E0E0);
  static const _darkColor = Color(0xFFBDBDBD);

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = _lightColor;
    final darkPaint = Paint()..color = _darkColor;

    final cols = (size.width / _squareSize).ceil();
    final rows = (size.height / _squareSize).ceil();

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final isLight = (row + col).isEven;
        final paint = isLight ? lightPaint : darkPaint;
        canvas.drawRect(
          Rect.fromLTWH(
            col * _squareSize,
            row * _squareSize,
            _squareSize,
            _squareSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
