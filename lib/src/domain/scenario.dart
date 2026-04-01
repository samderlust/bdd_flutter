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

  Scenario(
    this.name,
    this.steps, {
    this.examples,
    this.decorators = const {},
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
  bool get isUnitTest => decorators.hasUnitTest;
  bool get isWidgetTest => decorators.hasWidgetTest;

  String get className {
    return name.toScenarioClassName;
  }

  String get getHash {
    return md5.convert(utf8.encode(toString())).toString();
  }
}
