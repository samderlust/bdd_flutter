class Manifest {
  final String version;
  final DateTime lastGenerated;
  final List<ManifestFeature> features;

  Manifest({
    this.version = '1.0',
    DateTime? lastGenerated,
    this.features = const [],
  }) : lastGenerated = lastGenerated ?? DateTime.now();
}

class ManifestFeature {
  final String path;
  final String lastModified;
  final String testFile;
  final List<ManifestScenario> scenarios;

  ManifestFeature({
    required this.path,
    required this.lastModified,
    required this.testFile,
    this.scenarios = const [],
  });
}

class ManifestScenario {
  final String name;
  final String hash;
  final String testMethod;

  ManifestScenario({
    required this.name,
    required this.hash,
    required this.testMethod,
  });
}
