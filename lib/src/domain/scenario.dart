import 'dart:convert';
import '../extensions/string_x.dart';
import 'package:crypto/crypto.dart';

import 'decorator.dart';
import 'step.dart';

/// A scenario is a collection of steps
class Scenario {
  String name;
  List<Step> steps;
  List<Map<String, String>>? examples;
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

extension ScenarioX on Scenario {
  bool get isUnitTest => decorators.hasUnitTest;
  bool get isWidgetTest => decorators.hasWidgetTest;

  /// Resolve whether this is a unit test considering feature-level decorators
  bool isUnitTestWithFeature(Set<Decorator> featureDecorators) {
    if (decorators.hasUnitTest) return true;
    if (decorators.hasWidgetTest) return false;
    if (featureDecorators.hasUnitTest) return true;
    return false;
  }

  String get className => name.toScenarioClassName;

  String classNameWithSuffix(String suffix) => name.toClassName(suffix);

  String get getHash {
    return md5.convert(utf8.encode(toString())).toString();
  }
}
