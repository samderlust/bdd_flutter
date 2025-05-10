import 'dart:io';
import 'package:bdd_flutter/src/feature/builder/bdd_builders/bdd_factory.dart';
import 'package:bdd_flutter/src/feature/builder/domain/bdd_options.dart';
import 'package:yaml/yaml.dart';

import '../constraints/file_extenstion.dart';

/// Executes the build command to generate test files from feature files
Future<void> generate(List<String> arguments) async {
  final options = parseConfig(arguments);
  final factory = BDDFactory.create(options);

  // loop through all the .feature files in the test/features directory
  final features = Directory('test/').listSync(recursive: true).where((file) => file.path.endsWith('.feature')).toList();

  final ignoredFiles = options.ignoreFeatures;

  for (final feature in features) {
    final featureFile = File(feature.path);
    final featureContent = featureFile.readAsStringSync();
    final parsedFeature = factory.featureBuilder.parseFeature(featureContent);
    if (ignoredFiles.contains(feature.path)) {
      print('Skipping ${feature.path} because it is ignored');
      continue;
    } else {
      print('Processing ${feature.path}');
    }

    //build scenarios
    final scenarios = await factory.scenarioBuilder.buildScenarioFile(parsedFeature);
    final scenariosFile = File('${feature.path.replaceAll('.feature', '')}${FileExtension.generatedScenarios}');
    scenariosFile.writeAsStringSync(scenarios);

    //build test file
    final testCases = await factory.testFileBuilder.buildTestFile(parsedFeature);
    final testFile = File('${feature.path.replaceAll('.feature', '')}${FileExtension.generatedTest}');
    testFile.writeAsStringSync(testCases);
  }
}

/// Parse configuration from .bdd_config.yaml and command line arguments
BDDOptions parseConfig(List<String> arguments) {
  // Start with default values
  bool generateWidgetTests = true;
  bool enableReporter = false;
  List<String> ignoreFeatures = [];

  // Try to load config file
  final configFile = File('.bdd_config.yaml');
  if (configFile.existsSync()) {
    try {
      final yaml = loadYaml(configFile.readAsStringSync());
      if (yaml != null) {
        generateWidgetTests = yaml['generate_widget_tests'] as bool? ?? generateWidgetTests;
        enableReporter = yaml['enable_reporter'] as bool? ?? enableReporter;
        ignoreFeatures = (yaml['ignore_features'] as YamlList?)?.cast<String>() ?? ignoreFeatures;
      }
    } catch (e) {
      print('Warning: Failed to parse .bdd_config.yaml: $e');
    }
  }

  // Override with command line arguments
  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    switch (arg) {
      case '--no-widget-tests':
        generateWidgetTests = false;
        break;
      case '--enable-reporter':
        enableReporter = true;
        break;
      case '--ignore':
        if (i + 1 < arguments.length) {
          ignoreFeatures.add(arguments[i + 1]);
          i++; // Skip the next argument as it's the feature to ignore
        }
        break;
    }
  }

  return BDDOptions(
    generateWidgetTests: generateWidgetTests,
    enableReporter: enableReporter,
    ignoreFeatures: ignoreFeatures,
  );
}
