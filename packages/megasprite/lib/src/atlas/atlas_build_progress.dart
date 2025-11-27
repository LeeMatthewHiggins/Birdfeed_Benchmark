enum AtlasBuildPhase {
  decoding,
  trimming,
  deduplicating,
  packing,
  compositing,
}

class AtlasBuildProgress {
  const AtlasBuildProgress({
    required this.phase,
    required this.current,
    required this.total,
    this.message,
  });

  final AtlasBuildPhase phase;
  final int current;
  final int total;
  final String? message;

  double get progress => total > 0 ? current / total : 0;

  String get phaseLabel => switch (phase) {
        AtlasBuildPhase.decoding => 'Decoding images',
        AtlasBuildPhase.trimming => 'Trimming sprites',
        AtlasBuildPhase.deduplicating => 'Finding duplicates',
        AtlasBuildPhase.packing => 'Packing atlas',
        AtlasBuildPhase.compositing => 'Compositing pages',
      };
}
