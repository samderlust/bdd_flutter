import 'dart:io';

import 'package:yaml/yaml.dart';

class Manifest {
  final String version;
  DateTime lastGenerated;
  final List<FeatureEntry> features;

  Manifest({
    required this.version,
    required this.lastGenerated,
    required this.features,
  });

  factory Manifest.initial() {
    return Manifest(
      version: '1.0',
      lastGenerated: DateTime.now(),
      features: [],
    );
  }

  String toYaml() {
    final buffer = StringBuffer();
    buffer.writeln('version: "$version"');
    buffer.writeln('last_generated: "${lastGenerated.toIso8601String()}"');
    buffer.writeln('features:');
    for (final feature in features) {
      buffer.writeln('  - path: "${feature.path}"');
      buffer.writeln('    last_modified: "${feature.lastModified.toIso8601String()}"');
      buffer.writeln('    test_file: "${feature.testFile}"');
      buffer.writeln('    scenarios:');
      for (final scenario in feature.scenarios) {
        buffer.writeln('      - name: "${scenario.name}"');
        buffer.writeln('        hash: "${scenario.hash}"');
        buffer.writeln('        line_start: ${scenario.lineStart}');
        buffer.writeln('        line_end: ${scenario.lineEnd}');
        buffer.writeln('        test_method: "${scenario.testMethod}"');
      }
    }
    return buffer.toString();
  }

  factory Manifest.fromYaml(Map<String, dynamic> yaml) {
    return Manifest(
      version: yaml['version'] as String,
      lastGenerated: DateTime.parse(yaml['last_generated'] as String),
      features: (yaml['features'] as List).map((f) => FeatureEntry.fromYaml(f as Map<String, dynamic>)).toList(),
    );
  }
}

class FeatureEntry {
  final String path;
  final DateTime lastModified;
  final String testFile;
  final List<ScenarioEntry> scenarios;

  FeatureEntry({
    required this.path,
    required this.lastModified,
    required this.testFile,
    required this.scenarios,
  });

  Map<String, dynamic> toYaml() {
    return {
      'path': path,
      'last_modified': lastModified.toIso8601String(),
      'test_file': testFile,
      'scenarios': scenarios.map((s) => s.toYaml()).toList(),
    };
  }

  factory FeatureEntry.fromYaml(Map<String, dynamic> yaml) {
    return FeatureEntry(
      path: yaml['path'] as String,
      lastModified: DateTime.parse(yaml['last_modified'] as String),
      testFile: yaml['test_file'] as String,
      scenarios: (yaml['scenarios'] as List).map((s) => ScenarioEntry.fromYaml(s as Map<String, dynamic>)).toList(),
    );
  }
}

class ScenarioEntry {
  final String name;
  final String hash;
  final int lineStart;
  final int lineEnd;
  final String testMethod;

  ScenarioEntry({
    required this.name,
    required this.hash,
    required this.lineStart,
    required this.lineEnd,
    required this.testMethod,
  });

  Map<String, dynamic> toYaml() {
    return {
      'name': name,
      'hash': hash,
      'line_start': lineStart,
      'line_end': lineEnd,
      'test_method': testMethod,
    };
  }

  factory ScenarioEntry.fromYaml(Map<String, dynamic> yaml) {
    return ScenarioEntry(
      name: yaml['name'] as String,
      hash: yaml['hash'] as String,
      lineStart: yaml['line_start'] as int,
      lineEnd: yaml['line_end'] as int,
      testMethod: yaml['test_method'] as String,
    );
  }
}

class ManifestManager {
  static const String bddDir = '.bdd_flutter';
  static const String manifestPath = '$bddDir/manifest.yaml';

  Future<void> ensureBDDDirectory() async {
    final dir = Directory(bddDir);
    if (!await dir.exists()) {
      await dir.create();
    }
  }

  Future<Manifest> readManifest() async {
    await ensureBDDDirectory();
    final file = File(manifestPath);

    if (!await file.exists()) {
      return Manifest.initial();
    }

    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content);
      // Convert YamlMap to Map<String, dynamic> and handle null values
      final Map<String, dynamic> yamlMap = Map<String, dynamic>.from(yaml as Map);

      // Ensure all required fields exist with default values
      final features = (yamlMap['features'] as List?) ?? [];
      final version = yamlMap['version'] as String? ?? '1.0';
      final lastGenerated = yamlMap['last_generated'] as String? ?? DateTime.now().toIso8601String();

      return Manifest(
        version: version,
        lastGenerated: DateTime.parse(lastGenerated),
        features: features.map((f) {
          final featureMap = Map<String, dynamic>.from(f as Map);
          return FeatureEntry(
            path: featureMap['path'] as String? ?? '',
            lastModified: DateTime.parse(featureMap['last_modified'] as String? ?? DateTime.now().toIso8601String()),
            testFile: featureMap['test_file'] as String? ?? '',
            scenarios: (featureMap['scenarios'] as List?)?.map((s) {
                  final scenarioMap = Map<String, dynamic>.from(s as Map);
                  return ScenarioEntry(
                    name: scenarioMap['name'] as String? ?? '',
                    hash: scenarioMap['hash'] as String? ?? '',
                    lineStart: scenarioMap['line_start'] as int? ?? 0,
                    lineEnd: scenarioMap['line_end'] as int? ?? 0,
                    testMethod: scenarioMap['test_method'] as String? ?? '',
                  );
                }).toList() ??
                [],
          );
        }).toList(),
      );
    } catch (e) {
      print('Warning: Failed to parse manifest file: $e');
      return Manifest.initial();
    }
  }

  Future<void> writeManifest(Manifest manifest) async {
    await ensureBDDDirectory();
    final file = File(manifestPath);
    await file.writeAsString(manifest.toYaml());
  }
}
