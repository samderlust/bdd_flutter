import 'dart:convert';
import '../extensions/string_x.dart';
import 'package:crypto/crypto.dart';

import 'decorator.dart';
import 'step.dart';

/// Represents a Gherkin scenario with its steps, examples, and decorators.
///
/// Each scenario generates an instance-based class with step methods.
/// Users implement the step logic; the test file instantiates and calls them.
class Scenario {
  /// The scenario name (text after `Scenario:`).
  String name;

  /// The steps in this scenario (Given/When/Then/And).
  List<Step> steps;

  /// Example rows for parameterized scenarios, if any.
  ///
  /// Each entry maps column header to cell value.
  List<Map<String, String>>? examples;

  /// Decorators applied to this scenario (e.g., `@unitTest`).
  Set<Decorator> decorators;

  Scenario(
    this.name,
    this.steps, {
    this.examples,
    this.decorators = const {},
  });

  @override
  String toString() {
    return 'Scenario(name: $name, steps: $steps, examples: $examples, decorators: $decorators)';
  }
}

/// Extension methods for [Scenario].
extension ScenarioX on Scenario {
  /// Whether this scenario has the `@unitTest` decorator.
  bool get isUnitTest => decorators.hasUnitTest;

  /// Whether this scenario has the `@widgetTest` decorator.
  bool get isWidgetTest => decorators.hasWidgetTest;

  /// Resolves whether this is a unit test, considering feature-level decorators.
  ///
  /// Scenario decorators take precedence. If the scenario has no test type
  /// decorator, falls back to [featureDecorators].
  bool isUnitTestWithFeature(Set<Decorator> featureDecorators) {
    if (decorators.hasUnitTest) return true;
    if (decorators.hasWidgetTest) return false;
    if (featureDecorators.hasUnitTest) return true;
    return false;
  }

  /// The generated class name using the default "Scenario" suffix.
  String get className => name.toScenarioClassName;

  /// The generated class name using a custom [suffix].
  String classNameWithSuffix(String suffix) => name.toClassName(suffix);

  /// MD5 hash of the scenario's content for change detection.
  String get getHash {
    return md5.convert(utf8.encode(toString())).toString();
  }
}
