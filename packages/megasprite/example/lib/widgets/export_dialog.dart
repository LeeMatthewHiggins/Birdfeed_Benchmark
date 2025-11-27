import 'package:flutter/material.dart';
import 'package:megasprite/megasprite.dart';

class ExportSettings {
  const ExportSettings({
    required this.metadataFormat,
    required this.baseName,
    required this.exportAsZip,
  });

  final SerializerFormat metadataFormat;
  final String baseName;
  final bool exportAsZip;
}

class ExportDialog extends StatefulWidget {
  const ExportDialog({
    this.initialMetadataFormat = SerializerFormat.texturePackerJson,
    super.key,
  });

  final SerializerFormat initialMetadataFormat;

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late SerializerFormat _metadataFormat;
  final _baseNameController = TextEditingController(text: 'atlas');
  bool _exportAsZip = true;

  @override
  void initState() {
    super.initState();
    _metadataFormat = widget.initialMetadataFormat;
  }

  @override
  void dispose() {
    _baseNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Export Atlas'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _baseNameController,
              decoration: const InputDecoration(
                labelText: 'Base Name',
                helperText: 'Files will be named: {base}_0.png, {base}.json, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Metadata Format',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<SerializerFormat>(
              segments: SerializerFormat.values.map((format) {
                return ButtonSegment(
                  value: format,
                  label: Text(_metadataLabel(format)),
                );
              }).toList(),
              selected: {_metadataFormat},
              onSelectionChanged: (selected) {
                setState(() => _metadataFormat = selected.first);
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Export as ZIP'),
              subtitle: const Text('Bundle all files into a single ZIP archive'),
              value: _exportAsZip,
              onChanged: (value) {
                setState(() => _exportAsZip = value);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final baseName = _baseNameController.text.trim();
            if (baseName.isEmpty) return;

            Navigator.of(context).pop(
              ExportSettings(
                metadataFormat: _metadataFormat,
                baseName: baseName,
                exportAsZip: _exportAsZip,
              ),
            );
          },
          child: const Text('Export'),
        ),
      ],
    );
  }

  String _metadataLabel(SerializerFormat format) {
    return switch (format) {
      SerializerFormat.texturePackerJson => 'TexturePacker',
      SerializerFormat.minimalJson => 'Minimal',
      SerializerFormat.yaml => 'YAML',
    };
  }
}
