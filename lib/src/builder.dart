// lib/builder.dart
import 'dart:async';

import 'package:bdd_flutter/src/parser.dart';
import 'package:build/build.dart';

import 'helpers/scenario_file_builder.dart';
import 'helpers/test_file_builder.dart';

/// A builder that generates test files from feature files
class BDDTestBuilder implements Builder {
  /// Whether to generate widget tests
  final bool generateWidgetTests;

  BDDTestBuilder({this.generateWidgetTests = true});

  @override
  final buildExtensions = const {
    r'.feature': ['.bdd.dart', '_scenarios.dart', '_test.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final scenarioOutputId = inputId.changeExtension('_scenarios.dart');
    final testOutputId = inputId.changeExtension('_test.dart');

    final featureContent = await buildStep.readAsString(inputId);
    final feature = parseFeatureFile(featureContent, generateWidgetTests);

    final scenarioContent = await buildScenarioFile(
      feature: feature,
      generateWidgetTests: generateWidgetTests,
    );
    await buildStep.writeAsString(scenarioOutputId, scenarioContent);

    final testContent = await buildTestFile(
      feature: feature,
      generateWidgetTests: generateWidgetTests,
    );
    await buildStep.writeAsString(testOutputId, testContent);
  }
}

Builder bddTestBuilder(BuilderOptions options) {
  final config = options.config;
  final generateWidgetTests = config['generate_widget_tests'] as bool? ?? true;
  return BDDTestBuilder(generateWidgetTests: generateWidgetTests);
}
