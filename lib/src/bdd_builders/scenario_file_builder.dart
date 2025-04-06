import 'package:build/build.dart';

import '../domain/scenario.dart';
import '../extensions/string_x.dart';

import '../domain/feature.dart';

class ScenariosFileBuilder {
  Future<void> build(BuildStep buildStep, Feature feature) async {
    final inputId = buildStep.inputId;
    final scenarioOutputId = inputId.changeExtension('_scenarios.dart');

    final scenarioContent = await buildScenarioFile(feature);
    await buildStep.writeAsString(scenarioOutputId, scenarioContent);
  }

  Future<String> buildScenarioFile(Feature feature) async {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    buffer.writeln();

    // Create a class for each scenario
    for (var scenario in feature.scenarios) {
      final isUnitTest = scenario.isUnitTest;

      buffer.writeln("class ${scenario.className} {");

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
}
