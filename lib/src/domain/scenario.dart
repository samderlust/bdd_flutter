import 'dart:convert';
import '../extensions/string_x.dart';
import 'package:crypto/crypto.dart';

import 'decorator.dart';
import 'step.dart';

/// A scenario is a collection of steps
class Scenario {
  /// The name of the scenario
  String name;

  /// The steps of the scenario
  List<Step> steps;

  /// The examples of the scenario
  List<Map<String, String>>? examples;

  /// The decorators of the scenario
  Set<Decorator> decorators;

  /// Custom class name from @className("...") decorator
  String? customClassName;

  Scenario(
    this.name,
    this.steps, {
    this.examples,
    this.decorators = const {},
    this.customClassName,
  });

  factory Scenario.init() => Scenario(
        '',
        [],
        examples: [],
        decorators: {},
      );

  @override
  String toString() {
    return 'Scenario(name: $name, steps: $steps, examples: $examples, decorators: $decorators)';
  }
}

extension ScenarioX on Scenario {
  /// Check if unit test — scenario decorator overrides, then fall back to feature
  bool get isUnitTest => decorators.hasUnitTest;
  bool get isWidgetTest => decorators.hasWidgetTest;

  /// Resolve whether this is a unit test considering feature-level decorators
  bool isUnitTestWithFeature(Set<Decorator> featureDecorators) {
    if (decorators.hasUnitTest) return true;
    if (decorators.hasWidgetTest) return false;
    // Fall back to feature-level
    if (featureDecorators.hasUnitTest) return true;
    return false;
  }

  String get className {
    if (customClassName != null) return customClassName!;
    return name.toScenarioClassName;
  }

  String get getHash {
    return md5.convert(utf8.encode(toString())).toString();
  }
}
