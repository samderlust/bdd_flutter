import 'dart:io';

import 'package:yaml/yaml.dart';

import '../../domain/config.dart';

class ConfigParser {
  static const String defaultConfigDir = '.bdd_flutter';
  static const String defaultConfigFile = '$defaultConfigDir/config.yaml';

  final String configFile;

  ConfigParser({String? configFile}) : configFile = configFile ?? defaultConfigFile;

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
      generateWidgetTests: yaml['generate_widget_tests'] as bool? ?? true,
      enableReporter: yaml['enable_reporter'] as bool? ?? false,
      ignoreFeatures: _parseStringList(yaml['ignore_features']),
    );
  }

  List<String> _parseStringList(dynamic value) {
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}
