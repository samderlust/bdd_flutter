// lib/builder.dart
import 'dart:async';

import 'package:bdd_flutter/src/feature/builder/domain/bdd_options.dart';
import 'package:build/build.dart';

import 'feature/builder/bdd_builders/bdd_factory.dart';

/// A builder that generates test files from feature files
class BDDTestBuilder implements Builder {
  final BDDOptions options;

  BDDTestBuilder({required this.options});

  @override
  final buildExtensions = const {
    r'.feature': ['.bdd_scenarios.g.dart', '.bdd_test.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Check if the feature file should be ignored
    if (options.ignoreFeatures.contains(buildStep.inputId.path)) {
      return;
    }

    final factory = BDDFactory.create(options);
    final feature = await factory.featureBuilder.build(buildStep);

    // Skip generation if feature is empty (due to @ignore)
    if (feature.name.isEmpty) {
      return;
    }

    await factory.scenarioBuilder.build(buildStep, feature);
    await factory.testFileBuilder.build(buildStep, feature);
  }
}

Builder bddTestBuilder(BuilderOptions options) {
  final config = options.config;
  final generateWidgetTests = config['generate_widget_tests'] as bool? ?? true;
  final enableReporter = config['enable_reporter'] as bool? ?? false;
  final ignoreFeatures = (config['ignore_features'] as List<dynamic>?)?.cast<String>() ?? [];

  final bddOptions = BDDOptions(
    generateWidgetTests: generateWidgetTests,
    enableReporter: enableReporter,
    ignoreFeatures: ignoreFeatures,
  );
  return BDDTestBuilder(options: bddOptions);
}
