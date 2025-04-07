import 'package:bdd_flutter/src/feature/builder/domain/bdd_options.dart';

import '../decorator.dart';

class DecoratorsValidator {
  static final _validFeatureDecoratorTypes = [
    DecoratorType.enableReporter,
    DecoratorType.disableReporter,
    DecoratorType.unitTest,
    DecoratorType.widgetTest,
  ];

  static final _validScenarioDecoratorTypes = [
    DecoratorType.unitTest,
    DecoratorType.widgetTest,
    DecoratorType.className,
  ];

  /// Get valid feature decorators
  ///
  /// This method validates the feature decorators and returns a new set of decorators
  /// that are valid. It also overrides the builder options if necessary.
  static Set<BDDDecorator> getValidFeatureDecorator(
    Set<BDDDecorator> decorators,
    BDDOptions builderOptions,
  ) {
    final tempSet = {...decorators};
    // check invalid decorators
    for (final decorator in tempSet) {
      if (!_validFeatureDecoratorTypes.contains(decorator.type)) {
        throw Exception(
          'Invalid feature decorator: ${decorator.type}',
        );
      }
    }
    // check invalid decorators combination
    if (tempSet.hasUnitTest && tempSet.hasWidgetTest) {
      throw Exception(
        'Cannot have both @unitTest and @widgetTest decorators at the same time',
      );
    }

    if (tempSet.hasEnableReporter && tempSet.hasDisableReporter) {
      throw Exception(
        'Cannot have both @enableReporter and @disableReporter decorators at the same time',
      );
    }

    //by default reporter is disabled, if enableReporter is set, override it
    if (builderOptions.enableReporter && !tempSet.hasDisableReporter) {
      tempSet.add(BDDDecorator.enableReporter());
    }
    return tempSet;
  }

  /// Get valid scenario decorators
  ///
  /// This method validates the scenario decorators and returns a new set of decorators
  /// that are valid. It also overrides the builder options if necessary.
  static validateScenarioDecorators(
    Set<BDDDecorator> decorators,
  ) {
    // check invalid decorators
    for (final decorator in decorators) {
      if (!_validScenarioDecoratorTypes.contains(decorator.type)) {
        throw Exception(
          'Invalid scenario decorator: ${decorator.type}',
        );
      }
    }

    // check invalid decorators combination
    if (decorators.hasUnitTest && decorators.hasWidgetTest) {
      throw Exception(
        'Cannot have both @unitTest and @widgetTest decorators at the same time',
      );
    }
  }
}
