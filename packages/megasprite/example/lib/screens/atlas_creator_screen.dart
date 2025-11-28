import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atlas_creator/controllers/atlas_selection_controller.dart';
import 'package:atlas_creator/services/atlas_creator_service.dart';
import 'package:atlas_creator/widgets/atlas_preview_panel.dart';
import 'package:atlas_creator/widgets/atlas_settings_panel.dart';
import 'package:atlas_creator/widgets/export_dialog.dart';
import 'package:atlas_creator/widgets/sprite_file_tree.dart';
import 'package:atlas_creator/widgets/sprite_info_panel.dart';
import 'package:flutter/material.dart';
import 'package:megasprite/megasprite.dart';

class AtlasCreatorScreen extends StatefulWidget {
  const AtlasCreatorScreen({super.key});

  @override
  State<AtlasCreatorScreen> createState() => _AtlasCreatorScreenState();
}

class _AtlasCreatorScreenState extends State<AtlasCreatorScreen> {
  final _service = AtlasCreatorService();
  final _sprites = <SpriteEntry>[];
  final _emptyFolders = <String>{};
  final _selectionController = AtlasSelectionController();
  AtlasResult? _result;
  bool _isBuilding = false;
  String? _error;
  AtlasBuildProgress? _buildProgress;

  AtlasSizePreset _sizePreset = AtlasSizePreset.size4k;
  int _padding = 1;
  bool _allowRotation = true;
  int _trimTolerance = 0;
  PackingAlgorithm _packingAlgorithm = PackingAlgorithm.maxRectsBssf;
  double _scalePercent = 100;

  Future<void> _onSpritesAdded(List<SpriteEntry> entries) async {
    setState(() {
      _sprites.addAll(entries);
      _error = null;
      for (final entry in entries) {
        final parts = entry.identifier.split('/');
        if (parts.length > 1) {
          final folder = parts.sublist(0, parts.length - 1).join('/');
          _emptyFolders.remove(folder);
        }
      }
    });
  }

  void _onFolderCreated(String folderName) {
    setState(() {
      _emptyFolders.add(folderName);
    });
  }

  void _onFolderDeleted(String folderName, List<SpriteEntry> spritesInFolder) {
    setState(() {
      _emptyFolders.remove(folderName);
      for (final sprite in spritesInFolder) {
        _sprites.remove(sprite);
      }
    });
  }

  void _onSpriteRemoved(SpriteEntry entry) {
    setState(() {
      _sprites.remove(entry);
    });
  }

  void _clearSprites() {
    setState(() {
      _sprites.clear();
      _emptyFolders.clear();
      _result?.dispose();
      _result = null;
      _error = null;
    });
  }

  Future<void> _buildAtlas() async {
    if (_sprites.isEmpty) return;

    setState(() {
      _isBuilding = true;
      _error = null;
      _buildProgress = null;
    });

    try {
      final sourceSprites = _sprites
          .map((e) => SourceSprite(identifier: e.identifier, imageBytes: e.bytes))
          .toList();

      final progressStream = _service.buildAtlasWithProgress(
        sprites: sourceSprites,
        sizePreset: _sizePreset,
        padding: _padding,
        allowRotation: _allowRotation,
        trimTolerance: _trimTolerance,
        packingAlgorithm: _packingAlgorithm,
        scalePercent: _scalePercent,
      );

      await for (final progress in progressStream) {
        setState(() {
          _buildProgress = progress;
        });
      }

      _result?.dispose();

      setState(() {
        _result = _service.getResult();
        _isBuilding = false;
        _buildProgress = null;
      });
    } on AtlasBuildException catch (e) {
      setState(() {
        _error = e.message;
        _isBuilding = false;
        _buildProgress = null;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _isBuilding = false;
        _buildProgress = null;
      });
    }
  }

  Future<void> _exportAtlas() async {
    if (_result == null) return;

    final settings = await showDialog<ExportSettings>(
      context: context,
      builder: (context) => const ExportDialog(),
    );

    if (settings == null) return;

    await _service.exportAtlas(_result!, settings);
  }

  @override
  void initState() {
    super.initState();
    _selectionController.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    _selectionController
      ..removeListener(_onSelectionChanged)
      ..dispose();
    _result?.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Creator'),
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export Atlas',
              onPressed: _exportAtlas,
            ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 320,
            child: Column(
              children: [
                Expanded(
                  child: SpriteFileTree(
                    sprites: _sprites,
                    selectionController: _selectionController,
                    onSpriteRemoved: _onSpriteRemoved,
                    onSpritesAdded: _onSpritesAdded,
                    emptyFolders: _emptyFolders,
                    onFolderCreated: _onFolderCreated,
                    onFolderDeleted: _onFolderDeleted,
                  ),
                ),
                if (_sprites.isNotEmpty || _emptyFolders.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: _clearSprites,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear'),
                        ),
                        const Spacer(),
                        Text('${_sprites.length} sprites'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _isBuilding
                      ? _BuildProgressView(progress: _buildProgress)
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            )
                          : AtlasPreviewPanel(
                              result: _result,
                              selectionController: _selectionController,
                            ),
                ),
                const Divider(height: 1),
                AtlasSettingsPanel(
                  sizePreset: _sizePreset,
                  padding: _padding,
                  allowRotation: _allowRotation,
                  trimTolerance: _trimTolerance,
                  packingAlgorithm: _packingAlgorithm,
                  scalePercent: _scalePercent,
                  canBuild: _sprites.isNotEmpty && !_isBuilding,
                  onSizePresetChanged: (value) => setState(() => _sizePreset = value),
                  onPaddingChanged: (value) => setState(() => _padding = value),
                  onAllowRotationChanged: (value) => setState(() => _allowRotation = value),
                  onTrimToleranceChanged: (value) => setState(() => _trimTolerance = value),
                  onPackingAlgorithmChanged: (value) => setState(() => _packingAlgorithm = value),
                  onScalePercentChanged: (value) => setState(() => _scalePercent = value),
                  onBuild: _buildAtlas,
                ),
              ],
            ),
          ),
          if (_selectionController.selectedSpriteId != null) ...[
            const VerticalDivider(width: 1),
            SizedBox(
              width: 280,
              child: SpriteInfoPanel(
                sprites: _sprites,
                selectionController: _selectionController,
                result: _result,
                atlasSizePreset: _sizePreset,
                onClose: _selectionController.clear,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BuildProgressView extends StatelessWidget {
  const _BuildProgressView({required this.progress});

  final AtlasBuildProgress? progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final prog = progress;

    if (prog == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: prog.progress,
                      strokeWidth: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(prog.progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      Text(
                        '${prog.current} / ${prog.total}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              prog.phaseLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (prog.message != null) ...[
              const SizedBox(height: 8),
              Text(
                prog.message!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SpriteEntry {
  SpriteEntry({
    required this.identifier,
    required this.bytes,
    this.thumbnail,
  });

  final String identifier;
  final Uint8List bytes;
  ui.Image? thumbnail;
}
