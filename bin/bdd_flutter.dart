import 'dart:convert';
import 'dart:io';

import 'package:bdd_flutter/bdd_flutter.dart';
import 'package:bdd_flutter/src/feature/builder/bdd_builders/bdd_factory.dart';
import 'package:bdd_flutter/src/feature/builder/domain/bdd_options.dart';
import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  if (arguments.contains('build')) {
    await build(arguments);
  } else if (arguments.contains('rename')) {
    rename();
  }
}

Future<void> build(List<String> arguments) async {
  // loop through all the .feature files in the test/features directory
  final features = Directory('test/').listSync(recursive: true).where((file) => file.path.endsWith('.feature')).toList();

  final ignoredFiles = getIgnoredFiles();
  print(ignoredFiles);

  for (final feature in features) {
    print(feature.path);
  }

  final options = BuilderOptions({'generate_widget_tests': true});
  final factory = BDDFactory.create(BDDOptions());

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

void rename() {}

List<String> getIgnoredFiles() {
  // parse build.yaml file, get the ignore_features property
  final buildYaml = File('build.yaml');
  final yaml = loadYaml(buildYaml.readAsStringSync());
  if (yaml == null) return [];

  final targets = yaml['targets'];
  if (targets == null) return [];

  final defaultTarget = targets['\$default'];
  if (defaultTarget == null) return [];

  final builders = defaultTarget['builders'];
  if (builders == null) return [];

  final bddBuilder = builders['bdd_flutter|bdd_test_builder'];
  if (bddBuilder == null) return [];

  final options = bddBuilder['options'];
  if (options == null) return [];

  final ignoreFeatures = options['ignore_features'];
  if (ignoreFeatures == null) return [];

  return List<String>.from(ignoreFeatures);
}
