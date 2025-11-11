import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class RiveFileDropZone extends StatefulWidget {
  const RiveFileDropZone({
    required this.onFileDropped,
    this.fileName,
    super.key,
  });

  final Future<bool> Function(List<int> bytes, String fileName) onFileDropped;
  final String? fileName;

  @override
  State<RiveFileDropZone> createState() => _RiveFileDropZoneState();
}

class _RiveFileDropZoneState extends State<RiveFileDropZone> {
  bool _isDragging = false;
  bool _isLoading = false;
  String? _errorMessage;

  static const _allowedExtensions = ['.riv'];
  static const _borderRadius = 8.0;
  static const _dropZoneHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: _handleDrop,
      child: Container(
        height: _dropZoneHeight,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border.all(
            color: _getBorderColor(),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: Center(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('Loading Rive file...'),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (widget.fileName != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 32),
          const SizedBox(height: 8),
          Text(
            'Loaded: ${widget.fileName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Drop a new .riv file to replace',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }

    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.upload_file, size: 32),
        SizedBox(height: 8),
        Text(
          'Drag and drop a .riv file here',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getBackgroundColor() {
    if (_isDragging) return Colors.blue.withValues(alpha: 0.1);
    if (_errorMessage != null) return Colors.red.withValues(alpha: 0.1);
    if (widget.fileName != null) return Colors.green.withValues(alpha: 0.05);
    return Colors.grey.withValues(alpha: 0.1);
  }

  Color _getBorderColor() {
    if (_isDragging) return Colors.blue;
    if (_errorMessage != null) return Colors.red;
    if (widget.fileName != null) return Colors.green;
    return Colors.grey;
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    setState(() {
      _isDragging = false;
      _errorMessage = null;
    });

    if (details.files.isEmpty) {
      setState(() {
        _errorMessage = 'No file provided';
      });
      return;
    }

    final file = details.files.first;
    final fileName = file.name;

    if (!_isValidRiveFile(fileName)) {
      setState(() {
        _errorMessage = 'Invalid file type. Only .riv files are supported.';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bytes = await file.readAsBytes();
      final success = await widget.onFileDropped(bytes, fileName);

      if (!mounted) return;

      if (success) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load Rive file';
        });
      }
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error reading file';
      });
    }
  }

  bool _isValidRiveFile(String fileName) {
    final lowerName = fileName.toLowerCase();
    return _allowedExtensions.any(lowerName.endsWith);
  }
}
