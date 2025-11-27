import 'package:atlas_creator/screens/atlas_creator_screen.dart';
import 'package:atlas_creator/services/sprite_drop_handler.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SpriteDropZone extends StatefulWidget {
  const SpriteDropZone({
    required this.onSpritesAdded,
    super.key,
  });

  final void Function(List<SpriteEntry>) onSpritesAdded;

  @override
  State<SpriteDropZone> createState() => _SpriteDropZoneState();
}

class _SpriteDropZoneState extends State<SpriteDropZone> {
  final _dropHandler = SpriteDropHandler();
  bool _isDragging = false;
  bool _isProcessing = false;

  Future<void> _handleDrop(DropDoneDetails details) async {
    setState(() => _isProcessing = true);

    try {
      final entries = await _dropHandler.processDropDetails(details);
      if (entries.isNotEmpty) {
        widget.onSpritesAdded(entries);
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'zip'],
      withData: true,
    );

    if (result == null) return;

    setState(() => _isProcessing = true);

    try {
      final entries = await _dropHandler.processPickerFiles(result.files);
      if (entries.isNotEmpty) {
        widget.onSpritesAdded(entries);
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: _handleDrop,
      child: GestureDetector(
        onTap: _isProcessing ? null : _pickFiles,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDragging ? colorScheme.primary : colorScheme.outline,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _isDragging
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.surface,
          ),
          child: Center(
            child: _isProcessing
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Drop images, folders, or zip files here',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'or click to browse',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PNG, JPG, GIF, WebP, BMP, ZIP',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
