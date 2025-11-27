import 'package:atlas_creator/controllers/atlas_selection_controller.dart';
import 'package:flutter/material.dart';
import 'package:megasprite/megasprite.dart';

class AtlasPreviewPanel extends StatefulWidget {
  const AtlasPreviewPanel({
    required this.result,
    required this.selectionController,
    super.key,
  });

  final AtlasResult? result;
  final AtlasSelectionController selectionController;

  @override
  State<AtlasPreviewPanel> createState() => _AtlasPreviewPanelState();
}

class _AtlasPreviewPanelState extends State<AtlasPreviewPanel> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    widget.selectionController.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(AtlasPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.result != oldWidget.result) {
      _currentPage = 0;
    }
    if (widget.selectionController != oldWidget.selectionController) {
      oldWidget.selectionController.removeListener(_onSelectionChanged);
      widget.selectionController.addListener(_onSelectionChanged);
    }
  }

  @override
  void dispose() {
    widget.selectionController.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    setState(() {});
  }

  Rect? _getSelectedRect(AtlasPage page, String? selectedId) {
    if (selectedId == null) return null;

    for (final sprite in page.packedSprites) {
      if (sprite.identifier == selectedId) {
        return Rect.fromLTWH(
          sprite.x.toDouble(),
          sprite.y.toDouble(),
          sprite.packedWidth.toDouble(),
          sprite.packedHeight.toDouble(),
        );
      }
    }

    for (final alias in page.aliases) {
      if (alias.identifier == selectedId) {
        final sprite = alias.packedSprite;
        return Rect.fromLTWH(
          sprite.x.toDouble(),
          sprite.y.toDouble(),
          sprite.packedWidth.toDouble(),
          sprite.packedHeight.toDouble(),
        );
      }
    }

    return null;
  }

  void _handleTap(TapUpDetails details, Size viewSize, AtlasPage page) {
    final tapX = details.localPosition.dx / viewSize.width * page.width;
    final tapY = details.localPosition.dy / viewSize.height * page.height;

    String? foundId;

    for (final sprite in page.packedSprites) {
      final rect = Rect.fromLTWH(
        sprite.x.toDouble(),
        sprite.y.toDouble(),
        sprite.packedWidth.toDouble(),
        sprite.packedHeight.toDouble(),
      );
      if (rect.contains(Offset(tapX, tapY))) {
        foundId = sprite.identifier;
        break;
      }
    }

    if (foundId == null) {
      for (final alias in page.aliases) {
        final sprite = alias.packedSprite;
        final rect = Rect.fromLTWH(
          sprite.x.toDouble(),
          sprite.y.toDouble(),
          sprite.packedWidth.toDouble(),
          sprite.packedHeight.toDouble(),
        );
        if (rect.contains(Offset(tapX, tapY))) {
          foundId = alias.identifier;
          break;
        }
      }
    }

    final controller = widget.selectionController;
    if (foundId == controller.selectedSpriteId) {
      controller.select(null);
    } else if (foundId != null) {
      controller.select(foundId);
    } else {
      controller.select(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final result = widget.result;

    if (result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grid_view_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Add sprites and click Build Atlas to preview',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    final page = result.pages[_currentPage];
    final imageAspectRatio = page.image.width / page.image.height;
    final selectedId = widget.selectionController.selectedSpriteId;
    final selectedRect = _getSelectedRect(page, selectedId);

    return Column(
      children: [
        Expanded(
          child: ColoredBox(
            color: colorScheme.surfaceContainerLow,
            child: Center(
              child: InteractiveViewer(
                maxScale: 10,
                minScale: 0.1,
                child: AspectRatio(
                  aspectRatio: imageAspectRatio,
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapUp: (details) => _handleTap(
                            details,
                            constraints.biggest,
                            page,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(
                                painter: _CheckerboardPainter(
                                  color1: colorScheme.surfaceContainerLow,
                                  color2: colorScheme.surfaceContainerHigh,
                                ),
                              ),
                              RawImage(
                                image: page.image,
                                fit: BoxFit.contain,
                              ),
                              if (selectedRect != null)
                                CustomPaint(
                                  painter: _SelectionOverlayPainter(
                                    rect: selectedRect,
                                    imageWidth: page.width,
                                    imageHeight: page.height,
                                    color: colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            border: Border(
              top: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              _StatChip(
                icon: Icons.image,
                label: 'Sprites',
                value: '${result.totalSpriteCount}',
              ),
              const SizedBox(width: 16),
              _StatChip(
                icon: Icons.compress,
                label: 'Unique',
                value: '${result.uniqueSpriteCount}',
              ),
              if (result.duplicateCount > 0) ...[
                const SizedBox(width: 16),
                _StatChip(
                  icon: Icons.content_copy,
                  label: 'Duplicates',
                  value: '${result.duplicateCount}',
                ),
              ],
              const SizedBox(width: 16),
              _StatChip(
                icon: Icons.pie_chart,
                label: 'Efficiency',
                value: '${(result.overallEfficiency * 100).toStringAsFixed(1)}%',
              ),
              const Spacer(),
              if (result.pageCount > 1) ...[
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text('Page ${_currentPage + 1} / ${result.pageCount}'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < result.pageCount - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  _CheckerboardPainter({
    required this.color1,
    required this.color2,
  });

  final Color color1;
  final Color color2;

  static const double _cellSize = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    final cols = (size.width / _cellSize).ceil();
    final rows = (size.height / _cellSize).ceil();

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final isEven = (row + col).isEven;
        final rect = Rect.fromLTWH(
          col * _cellSize,
          row * _cellSize,
          _cellSize,
          _cellSize,
        );
        canvas.drawRect(rect, isEven ? paint1 : paint2);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter oldDelegate) {
    return color1 != oldDelegate.color1 || color2 != oldDelegate.color2;
  }
}

class _SelectionOverlayPainter extends CustomPainter {
  _SelectionOverlayPainter({
    required this.rect,
    required this.imageWidth,
    required this.imageHeight,
    required this.color,
  });

  final Rect rect;
  final int imageWidth;
  final int imageHeight;
  final Color color;

  static const double _strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    final scaledRect = Rect.fromLTWH(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.width * scaleX,
      rect.height * scaleY,
    );

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    canvas
      ..drawRect(scaledRect, fillPaint)
      ..drawRect(scaledRect, strokePaint);
  }

  @override
  bool shouldRepaint(_SelectionOverlayPainter oldDelegate) {
    return rect != oldDelegate.rect ||
        imageWidth != oldDelegate.imageWidth ||
        imageHeight != oldDelegate.imageHeight ||
        color != oldDelegate.color;
  }
}
