import 'dart:io';
import 'package:yaml/yaml.dart';

class BDDOptions {
  final bool generateWidgetTests;
  final bool enableReporter;
  final List<String> ignoreFeatures;
  final bool force;
  final bool newOnly;

  BDDOptions({
    required this.generateWidgetTests,
    required this.enableReporter,
    required this.ignoreFeatures,
    this.force = false,
    this.newOnly = false,
  });

  BDDOptions copyWith({
    bool? generateWidgetTests,
    bool? enableReporter,
    List<String>? ignoreFeatures,
    bool? force,
    bool? newOnly,
  }) {
    return BDDOptions(
      generateWidgetTests: generateWidgetTests ?? this.generateWidgetTests,
      enableReporter: enableReporter ?? this.enableReporter,
      ignoreFeatures: ignoreFeatures ?? this.ignoreFeatures,
      force: force ?? this.force,
      newOnly: newOnly ?? this.newOnly,
    );
  }

  static const String bddDir = '.bdd_flutter';
  static const String configPath = '$bddDir/config.yaml';

  static Future<void> ensureBDDDirectory() async {
    final dir = Directory(bddDir);
    if (!await dir.exists()) {
      await dir.create();
    }
  }

  static Future<BDDOptions> fromConfig() async {
    await ensureBDDDirectory();
    final configFile = File(configPath);

    // Start with default values
    bool generateWidgetTests = true;
    bool enableReporter = false;
    List<String> ignoreFeatures = [];

    if (await configFile.exists()) {
      try {
        final yaml = loadYaml(await configFile.readAsString());
        if (yaml != null) {
          generateWidgetTests = yaml['generate_widget_tests'] as bool? ?? generateWidgetTests;
          enableReporter = yaml['enable_reporter'] as bool? ?? enableReporter;
          ignoreFeatures = (yaml['ignore_features'] as YamlList?)?.cast<String>() ?? ignoreFeatures;
        }
      } catch (e) {
        print('Warning: Failed to parse config file: $e');
      }
    }

    return BDDOptions(
      generateWidgetTests: generateWidgetTests,
      enableReporter: enableReporter,
      ignoreFeatures: ignoreFeatures,
    );
  }

  static Future<void> writeConfig(BDDOptions options) async {
    await ensureBDDDirectory();
    final configFile = File(configPath);

    final config = {
      'generate_widget_tests': options.generateWidgetTests,
      'enable_reporter': options.enableReporter,
      'ignore_features': options.ignoreFeatures,
    };

    await configFile.writeAsString(config.toString());
  }
}
