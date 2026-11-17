import 'dart:io';

import 'package:yaml/yaml.dart';

import '../../domain/config.dart';
import '../../domain/steps_mode.dart';

/// Reads configuration from `.bdd_flutter/config.yaml`.
///
/// Returns [BDDConfig] with defaults for any missing options.
/// If the config file does not exist, all defaults are used.
class ConfigParser {
  static const String defaultConfigDir = '.bdd_flutter';
  static const String defaultConfigFile = '$defaultConfigDir/config.yaml';

  final String configFile;

  ConfigParser({String? configFile}) : configFile = configFile ?? defaultConfigFile;

  /// Loads the config file and returns a [BDDConfig].
  ///
  /// Throws [FormatException] for an unknown `steps_mode`.
  Future<BDDConfig> loadConfig() async {
    final file = File(configFile);

    if (!file.existsSync()) {
      return const BDDConfig();
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return const BDDConfig();
    }

    final yaml = loadYaml(content);
    if (yaml is! YamlMap) {
      return const BDDConfig();
    }

    return BDDConfig(
      testDir: yaml['test_dir'] as String? ?? 'test/',
      generateWidgetTests: yaml['generate_widget_tests'] as bool? ?? true,
      ignoreFeatures: _parseStringList(yaml['ignore_features']),
      additionalImports: _parseStringList(yaml['additional_imports']),
      stepsSuffix: yaml['steps_suffix'] as String? ?? 'Steps',
      legacyScenarioSuffix: yaml['scenario_suffix'] as String? ?? 'Scenario',
      stepsMode: StepsMode.parse(yaml['steps_mode']?.toString()),
    );
  }

  List<String> _parseStringList(dynamic value) {
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}
