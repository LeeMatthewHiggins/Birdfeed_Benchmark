import 'package:atlas_creator/controllers/atlas_selection_controller.dart';
import 'package:atlas_creator/screens/atlas_creator_screen.dart';
import 'package:atlas_creator/services/sprite_drop_handler.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class SpriteFileTree extends StatefulWidget {
  const SpriteFileTree({
    required this.sprites,
    required this.selectionController,
    required this.onSpriteRemoved,
    required this.onSpritesAdded,
    required this.emptyFolders,
    required this.onFolderCreated,
    required this.onFolderDeleted,
    super.key,
  });

  final List<SpriteEntry> sprites;
  final AtlasSelectionController selectionController;
  final void Function(SpriteEntry) onSpriteRemoved;
  final void Function(List<SpriteEntry>) onSpritesAdded;
  final Set<String> emptyFolders;
  final void Function(String) onFolderCreated;
  final void Function(String folderName, List<SpriteEntry> spritesInFolder) onFolderDeleted;

  @override
  State<SpriteFileTree> createState() => _SpriteFileTreeState();
}

class _SpriteFileTreeState extends State<SpriteFileTree> {
  final _dropHandler = SpriteDropHandler();
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    widget.selectionController.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(SpriteFileTree oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  Map<String, List<SpriteEntry>> _groupByFolder() {
    final groups = <String, List<SpriteEntry>>{};

    for (final folder in widget.emptyFolders) {
      groups[folder] = [];
    }

    for (final sprite in widget.sprites) {
      final parts = sprite.identifier.split('/');
      final folder =
          parts.length > 1 ? parts.sublist(0, parts.length - 1).join('/') : '';

      groups.putIfAbsent(folder, () => []).add(sprite);
    }

    return Map.fromEntries(
      groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Future<void> _handleRootDrop(DropDoneDetails details) async {
    final entries = await _dropHandler.processDropDetails(details);
    if (entries.isNotEmpty) {
      widget.onSpritesAdded(entries);
    }
  }

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();

    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (folderName != null && folderName.isNotEmpty) {
      widget.onFolderCreated(folderName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final groups = _groupByFolder();
    final selectedId = widget.selectionController.selectedSpriteId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Text(
                'Sprites',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                tooltip: 'New Folder',
                onPressed: _showCreateFolderDialog,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: DropTarget(
            onDragEntered: (_) => setState(() => _isDragging = true),
            onDragExited: (_) => setState(() => _isDragging = false),
            onDragDone: _handleRootDrop,
            child: Container(
              decoration: BoxDecoration(
                border: _isDragging
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : null,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final entry = groups.entries.elementAt(index);
                  final folder = entry.key;
                  final sprites = entry.value;

                  return _FolderSection(
                    folder: folder,
                    sprites: sprites,
                    selectedSpriteId: selectedId,
                    onSpriteRemoved: widget.onSpriteRemoved,
                    onSpriteSelected: (id) =>
                        widget.selectionController.toggle(id ?? ''),
                    onSpritesDropped: widget.onSpritesAdded,
                    onFolderDeleted: widget.onFolderDeleted,
                    dropHandler: _dropHandler,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FolderSection extends StatefulWidget {
  const _FolderSection({
    required this.folder,
    required this.sprites,
    required this.onSpriteRemoved,
    required this.onSpriteSelected,
    required this.onSpritesDropped,
    required this.onFolderDeleted,
    required this.dropHandler,
    this.selectedSpriteId,
  });

  final String folder;
  final List<SpriteEntry> sprites;
  final String? selectedSpriteId;
  final void Function(SpriteEntry) onSpriteRemoved;
  final void Function(String?) onSpriteSelected;
  final void Function(List<SpriteEntry>) onSpritesDropped;
  final void Function(String, List<SpriteEntry>) onFolderDeleted;
  final SpriteDropHandler dropHandler;

  @override
  State<_FolderSection> createState() => _FolderSectionState();
}

class _FolderSectionState extends State<_FolderSection> {
  bool _isExpanded = true;
  bool _isDraggingOver = false;

  bool get _canDelete => widget.folder.isNotEmpty;

  @override
  void didUpdateWidget(_FolderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedId = widget.selectedSpriteId;
    if (selectedId != null && selectedId != oldWidget.selectedSpriteId) {
      final containsSelected =
          widget.sprites.any((s) => s.identifier == selectedId);
      if (containsSelected && !_isExpanded) {
        setState(() => _isExpanded = true);
      }
    }
  }

  Future<void> _handleFolderDrop(DropDoneDetails details) async {
    final folderPrefix = widget.folder.isEmpty ? null : widget.folder;
    final entries = await widget.dropHandler.processDropDetails(
      details,
      folderPrefix: folderPrefix,
    );
    if (entries.isNotEmpty) {
      widget.onSpritesDropped(entries);
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final spriteCount = widget.sprites.length;
    final folderName = widget.folder;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          spriteCount == 0
              ? 'Delete folder "$folderName"?'
              : 'Delete folder "$folderName" and its $spriteCount sprite${spriteCount == 1 ? '' : 's'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      widget.onFolderDeleted(widget.folder, widget.sprites);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDraggingOver = true),
      onDragExited: (_) => setState(() => _isDraggingOver = false),
      onDragDone: _handleFolderDrop,
      child: Container(
        decoration: _isDraggingOver
            ? BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primary, width: 2),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _isExpanded ? Icons.folder_open : Icons.folder,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.folder.isEmpty ? '(root)' : widget.folder,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${widget.sprites.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                    const SizedBox(width: 4),
                    if (_canDelete)
                      InkWell(
                        onTap: _showDeleteConfirmation,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded && widget.sprites.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Column(
                  children: widget.sprites.map((sprite) {
                    final filename = sprite.identifier.split('/').last;
                    final isSelected =
                        sprite.identifier == widget.selectedSpriteId;
                    return _SpriteItem(
                      filename: filename,
                      isSelected: isSelected,
                      onTap: () => widget.onSpriteSelected(
                        isSelected ? null : sprite.identifier,
                      ),
                      onRemove: () => widget.onSpriteRemoved(sprite),
                    );
                  }).toList(),
                ),
              ),
            if (_isDraggingOver && widget.sprites.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 4, bottom: 4),
                child: Text(
                  'Drop files here',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpriteItem extends StatelessWidget {
  const _SpriteItem({
    required this.filename,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  final String filename;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: isSelected
            ? BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Row(
          children: [
            Icon(
              Icons.image_outlined,
              size: 16,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                filename,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : null,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
