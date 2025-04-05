import '../domain/scenario.dart';

import '../domain/feature.dart';
import '../extensions/string_x.dart';

Future<String> buildScenarioFile({
  required Feature feature,
  required bool generateWidgetTests,
}) async {
  final buffer = StringBuffer();
  buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
  buffer.writeln();

  // Create a class for each scenario
  for (var scenario in feature.scenarios) {
    final isUnitTest = scenario.isUnitTest;

    final className = scenario.name.toClassName;
    buffer.writeln("class $className {");

    // Create static methods for each step in the scenario
    for (var step in scenario.steps) {
      final methodName = step.text.toMethodName;
      final params = _extractMethodParams(step.text);

      if (!isUnitTest) {
        buffer.writeln(
          "  static Future<void> $methodName(WidgetTester tester${params.isNotEmpty ? ', $params' : ''}) async {",
        );
      } else {
        buffer.writeln(
          "  static Future<void> $methodName(${params.isNotEmpty ? params : ''}) async {",
        );
      }
      buffer.writeln("    // TODO: Implement ${step.keyword} ${step.text}");
      buffer.writeln("  }");
      buffer.writeln();
    }

    buffer.writeln("}");
    buffer.writeln();
  }

  // await buildStep.writeAsString(outputId, buffer.toString());
  return buffer.toString();
}

String _extractMethodParams(String stepText) {
  final params = <String>[];
  final regex = RegExp(r'<(\w+)>');
  final matches = regex.allMatches(stepText);

  for (var match in matches) {
    final paramName = match.group(1)!;
    params.add('dynamic $paramName');
  }

  return params.join(', ');
}
