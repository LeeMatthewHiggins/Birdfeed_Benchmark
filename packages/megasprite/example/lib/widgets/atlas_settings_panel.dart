import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:megasprite/megasprite.dart';

class AtlasSettingsPanel extends StatelessWidget {
  const AtlasSettingsPanel({
    required this.sizePreset,
    required this.padding,
    required this.allowRotation,
    required this.trimTolerance,
    required this.packingAlgorithm,
    required this.scalePercent,
    required this.canBuild,
    required this.onSizePresetChanged,
    required this.onPaddingChanged,
    required this.onAllowRotationChanged,
    required this.onTrimToleranceChanged,
    required this.onPackingAlgorithmChanged,
    required this.onScalePercentChanged,
    required this.onBuild,
    super.key,
  });

  static const _scaleOptions = [5.0, 12.5, 25.0, 50.0, 75.0, 100.0];

  static String _formatPercent(double value) {
    return value == value.truncateToDouble() ? '${value.toInt()}%' : '$value%';
  }

  final AtlasSizePreset sizePreset;
  final int padding;
  final bool allowRotation;
  final int trimTolerance;
  final PackingAlgorithm packingAlgorithm;
  final double scalePercent;
  final bool canBuild;
  final void Function(AtlasSizePreset) onSizePresetChanged;
  final void Function(int) onPaddingChanged;
  final ValueChanged<bool> onAllowRotationChanged;
  final void Function(int) onTrimToleranceChanged;
  final void Function(PackingAlgorithm) onPackingAlgorithmChanged;
  final ValueChanged<double> onScalePercentChanged;
  final VoidCallback onBuild;

  static const _webSupportedPresets = [
    AtlasSizePreset.size512,
    AtlasSizePreset.size1k,
    AtlasSizePreset.size2k,
    AtlasSizePreset.size4k,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const availablePresets =
        kIsWeb ? _webSupportedPresets : AtlasSizePreset.values;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
      ),
      child: Row(
        children: [
          _SettingItem(
            label: 'Size',
            child: DropdownButton<AtlasSizePreset>(
              value: sizePreset,
              underline: const SizedBox.shrink(),
              isDense: true,
              items: availablePresets.map((preset) {
                return DropdownMenuItem(
                  value: preset,
                  child: Text(preset.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onSizePresetChanged(value);
              },
            ),
          ),
          const SizedBox(width: 24),
          _SettingItem(
            label: 'Padding',
            child: SizedBox(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: padding > 0
                        ? () => onPaddingChanged(padding - 1)
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      '$padding px',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: padding < 16
                        ? () => onPaddingChanged(padding + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          _SettingItem(
            label: 'Rotation',
            child: Switch(
              value: allowRotation,
              onChanged: onAllowRotationChanged,
            ),
          ),
          const SizedBox(width: 24),
          _SettingItem(
            label: 'Trim Tolerance',
            child: SizedBox(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: trimTolerance > AtlasBuilderConfig.minTrimTolerance
                        ? () => onTrimToleranceChanged(trimTolerance - 1)
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      '$trimTolerance',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: trimTolerance < AtlasBuilderConfig.maxTrimTolerance
                        ? () => onTrimToleranceChanged(trimTolerance + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          _SettingItem(
            label: 'Packing',
            child: DropdownButton<PackingAlgorithm>(
              value: packingAlgorithm,
              underline: const SizedBox.shrink(),
              isDense: true,
              items: PackingAlgorithm.values.map((alg) {
                return DropdownMenuItem(
                  value: alg,
                  child: Text(alg.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onPackingAlgorithmChanged(value);
              },
            ),
          ),
          const SizedBox(width: 24),
          _SettingItem(
            label: 'Scale',
            child: DropdownButton<double>(
              value: scalePercent,
              underline: const SizedBox.shrink(),
              isDense: true,
              items: _scaleOptions.map((scale) {
                return DropdownMenuItem(
                  value: scale,
                  child: Text(_formatPercent(scale)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onScalePercentChanged(value);
              },
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: canBuild ? onBuild : null,
            icon: const Icon(Icons.build),
            label: const Text('Build Atlas'),
          ),
        ],
      ),
    );
  }

}

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
