/// Tracks the state of generated files in `.bdd_flutter/manifest.yaml`.
///
/// The manifest enables incremental builds by storing hashes of each scenario.
/// On subsequent builds, only new or changed scenarios trigger generation.
class Manifest {
  /// Manifest format version.
  final String version;

  /// Timestamp of the last generation run.
  final DateTime lastGenerated;

  /// List of tracked feature files and their scenarios.
  final List<ManifestFeature> features;

  Manifest({
    this.version = '1.0',
    DateTime? lastGenerated,
    this.features = const [],
  }) : lastGenerated = lastGenerated ?? DateTime.now();
}

/// A feature entry in the manifest, tracking its file and scenarios.
class ManifestFeature {
  /// Path to the `.feature` file.
  final String path;

  /// ISO 8601 timestamp of the feature file's last modification.
  final String lastModified;

  /// Path to the generated `.bdd_test.dart` file.
  final String testFile;

  /// Tracked scenarios with their content hashes.
  final List<ManifestScenario> scenarios;

  ManifestFeature({
    required this.path,
    required this.lastModified,
    required this.testFile,
    this.scenarios = const [],
  });
}

/// A scenario entry in the manifest, identified by its content hash.
class ManifestScenario {
  /// The scenario name.
  final String name;

  /// MD5 hash of the scenario's content (name, steps, examples, decorators).
  final String hash;

  /// The generated test method name.
  final String testMethod;

  ManifestScenario({
    required this.name,
    required this.hash,
    required this.testMethod,
  });
}
