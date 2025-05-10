import 'dart:developer' as dev;
import 'dart:io';

import 'package:bdd_flutter/src/feature/builder/bdd_builders/bdd_factory.dart';
import 'package:bdd_flutter/src/feature/builder/domain/bdd_options.dart';
import 'package:yaml/yaml.dart';
import 'src/rename.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    await build(arguments);
  } else if (arguments.first == 'rename') {
    print('rename');
    rename(arguments.skip(1).toList());
  }
}

Future<void> build(List<String> arguments) async {
  // loop through all the .feature files in the test/features directory
  final features = Directory('test/').listSync(recursive: true).where((file) => file.path.endsWith('.feature')).toList();

  final options = getBDDOptions();
  final factory = BDDFactory.create(options);

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
    final scenariosFile = File('${feature.path.replaceAll('.feature', '')}.bdd_scenarios.g.dart');
    scenariosFile.writeAsStringSync(scenarios);

    //build test file
    final testCases = await factory.testFileBuilder.buildTestFile(parsedFeature);
    final testFile = File('${feature.path.replaceAll('.feature', '')}.bdd_test.g.dart');
    testFile.writeAsStringSync(testCases);
  }
}

BDDOptions getBDDOptions() {
  final buildYaml = File('build.yaml');
  final yaml = loadYaml(buildYaml.readAsStringSync());
  if (yaml == null) return BDDOptions();

  final targets = yaml['targets'];
  if (targets == null) return BDDOptions();

  final defaultTarget = targets['\$default'];
  if (defaultTarget == null) return BDDOptions();

  final builders = defaultTarget['builders'];
  if (builders == null) return BDDOptions();

  final bddBuilder = builders['bdd_flutter|bdd_test_builder'];
  if (bddBuilder == null) return BDDOptions();

  final options = bddBuilder['options'];
  if (options == null) return BDDOptions();

  return BDDOptions(
    generateWidgetTests: options['generate_widget_tests'] as bool? ?? true,
    enableReporter: options['enable_reporter'] as bool? ?? false,
    ignoreFeatures: (options['ignore_features'] as YamlList?)?.cast<String>() ?? [],
  );
}
