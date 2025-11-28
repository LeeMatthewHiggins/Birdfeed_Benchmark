enum AtlasSizePreset {
  size512(512, '512'),
  size1k(1024, '1K'),
  size2k(2048, '2K'),
  size4k(4096, '4K'),
  size8k(8192, '8K');

  const AtlasSizePreset(this.dimension, this.label);

  final int dimension;
  final String label;
}

enum PackingAlgorithm {
  maxRectsBssf('MaxRects BSSF'),
  maxRectsBaf('MaxRects BAF'),
  shelf('Shelf');

  const PackingAlgorithm(this.label);

  final String label;
}

class AtlasBuilderConfig {
  const AtlasBuilderConfig._();

  static const int defaultPadding = 1;
  static const int minPadding = 0;
  static const int maxPadding = 16;
  static const bool defaultAllowRotation = true;
  static const AtlasSizePreset defaultSizePreset = AtlasSizePreset.size4k;
  static const int defaultTrimTolerance = 0;
  static const int minTrimTolerance = 0;
  static const int maxTrimTolerance = 128;
  static const PackingAlgorithm defaultPackingAlgorithm =
      PackingAlgorithm.maxRectsBssf;
  static const double defaultScalePercent = 100;
}
