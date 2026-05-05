import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../../domain/manifest.dart';

/// Reads and writes the manifest file (`.bdd_flutter/manifest.yaml`).
///
/// The manifest tracks generated features and their scenario hashes,
/// enabling incremental builds that skip unchanged content.
class ManifestParser {
  static const String defaultManifestDir = '.bdd_flutter';
  static const String defaultManifestFile = '$defaultManifestDir/manifest.yaml';

  final String manifestDir;
  final String manifestFile;

  ManifestParser({String? manifestDir, String? manifestFile})
      : manifestDir = manifestDir ?? defaultManifestDir,
        manifestFile = manifestFile ?? defaultManifestFile;

  /// Loads the manifest file and returns a [Manifest].
  ///
  /// Returns an empty manifest if the file does not exist.
  Future<Manifest> loadManifest() async {
    final file = File(manifestFile);

    if (!file.existsSync()) {
      return Manifest();
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return Manifest();
    }

    final yaml = loadYaml(content);
    if (yaml is! YamlMap) {
      return Manifest();
    }

    final features = <ManifestFeature>[];
    final yamlFeatures = yaml['features'];
    if (yamlFeatures is YamlList) {
      for (final f in yamlFeatures) {
        if (f is! YamlMap) continue;
        final scenarios = <ManifestScenario>[];
        final yamlScenarios = f['scenarios'];
        if (yamlScenarios is YamlList) {
          for (final s in yamlScenarios) {
            if (s is! YamlMap) continue;
            scenarios.add(ManifestScenario(
              name: s['name']?.toString() ?? '',
              hash: s['hash']?.toString() ?? '',
              testMethod: s['test_method']?.toString() ?? '',
            ));
          }
        }
        features.add(ManifestFeature(
          path: f['path']?.toString() ?? '',
          lastModified: f['last_modified']?.toString() ?? '',
          testFile: f['test_file']?.toString() ?? '',
          scenarios: scenarios,
        ));
      }
    }

    return Manifest(
      version: yaml['version']?.toString() ?? '1.0',
      lastGenerated: DateTime.tryParse(yaml['last_generated']?.toString() ?? ''),
      features: features,
    );
  }

  /// Saves the [manifest] to the manifest file.
  ///
  /// Creates the `.bdd_flutter` directory if it does not exist.
  ///
  /// Output is JSON, which is a strict subset of YAML 1.2 — `loadManifest()` parses
  /// it unchanged. Using `JsonEncoder` delegates string escaping to `dart:convert`,
  /// preventing malformed output for scenario names or paths containing quotes,
  /// colons, or other YAML-significant characters.
  Future<void> saveManifest(Manifest manifest) async {
    final dir = Directory(manifestDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final encoded = const JsonEncoder.withIndent('  ').convert(manifest.toMap());
    await File(manifestFile).writeAsString(encoded);
  }

  /// Finds a feature entry in the [manifest] by file [path].
  ///
  /// Returns `null` if the feature is not tracked.
  ManifestFeature? findFeature(Manifest manifest, String path) {
    for (final feature in manifest.features) {
      if (feature.path == path) return feature;
    }
    return null;
  }
}
