import '../constraints/file_constraint.dart';

import 'background.dart';
import 'decorator.dart';
import 'scenario.dart';

/// Represents a parsed Gherkin feature file.
///
/// A feature contains a name, file path, optional background, a list of
/// scenarios, and any decorators applied at the feature level.
class Feature {
  /// The feature name (text after `Feature:`).
  String name;

  /// The file path of the `.feature` file.
  String path;

  /// The scenarios defined in this feature.
  List<Scenario> scenarios;

  /// Optional background steps shared by all scenarios.
  Background? background;

  /// Decorators applied at the feature level (e.g., `@unitTest`).
  Set<Decorator> decorators;

  Feature({
    required this.name,
    required this.path,
    required this.scenarios,
    required this.decorators,
    this.background,
  });
}

/// Extension methods for [Feature].
extension FeatureX on Feature {
  /// The generated scenarios file name (e.g., `counter.bdd_scenarios.dart`).
  String get scenariosFileName {
    return '${fileName.replaceAll('.feature', '')}${FileConstraint.generatedScenarios}';
  }

  /// The generated test file name (e.g., `counter.bdd_test.dart`).
  String get testFileName {
    return '${fileName.replaceAll('.feature', '')}${FileConstraint.generatedTest}';
  }

  /// The base file name without directory path or `.feature` extension.
  String get fileName {
    return path.split('/').last.replaceAll('.feature', '');
  }
}
