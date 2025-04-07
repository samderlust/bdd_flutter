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
    r'.feature': ['.bdd.dart', '_scenarios.dart', '_test.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final factory = BDDFactory.create(options);

    final feature = await factory.featureBuilder.build(buildStep);
    if (feature == null) {
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
