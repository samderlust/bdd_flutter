// lib/builder.dart
import 'dart:async';

import 'package:bdd_flutter/src/feature/builder/domain/bdd_ignore.dart';
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
    await BDDIgnore.initialize();

    final factory = BDDFactory.create(options);
    final feature = await factory.featureBuilder.build(buildStep);

    // Check if we should ignore the generated files
    final outputId = buildStep.inputId.changeExtension('.bdd_test.g.dart');

    if (BDDIgnore.shouldIgnore(outputId.path)) {
      return;
    }

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

  final bddOptions = BDDOptions(
    generateWidgetTests: generateWidgetTests,
    enableReporter: enableReporter,
  );
  return BDDTestBuilder(options: bddOptions);
}
