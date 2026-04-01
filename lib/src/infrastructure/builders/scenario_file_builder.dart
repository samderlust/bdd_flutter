import '../../domain/decorator.dart';
import '../../extensions/string_x.dart';
import '../../domain/feature.dart';
import '../../domain/scenario.dart';
import '../../domain/step.dart';

class ScenariosFileBuilder {
  Future<String> buildScenarioFile(Feature feature) async {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    buffer.writeln();

    if (feature.background != null) {
      buffer.writeln("class ${feature.name}Background {");
      for (var step in feature.background!.steps) {
        final methodName = step.methodName;
        final params = extractMethodParams(step.text);
        buffer.writeln(
          "  Future<void> $methodName(${params.isNotEmpty ? params : ''}) async {",
        );
        buffer.writeln("    // TODO: Implement ${step.keyword} ${step.text}");
        buffer.writeln("  }");
        buffer.writeln();
      }
      buffer.writeln("}");
      buffer.writeln();
    }

    for (var scenario in feature.scenarios) {
      if (scenario.decorators.hasIgnore) continue;

      // Resolve unit test considering feature-level decorators
      final isUnitTest = scenario.isUnitTestWithFeature(feature.decorators);

      buffer.writeln("class ${scenario.className} {");

      for (var step in scenario.steps) {
        final methodName = step.methodName;
        final params = extractMethodParams(step.text);

        if (!isUnitTest) {
          buffer.writeln(
            "  Future<void> $methodName(WidgetTester tester${params.isNotEmpty ? ', $params' : ''}) async {",
          );
        } else {
          buffer.writeln(
            "  Future<void> $methodName(${params.isNotEmpty ? params : ''}) async {",
          );
        }
        buffer.writeln("    // TODO: Implement ${step.keyword} ${step.text}");
        buffer.writeln("  }");
        buffer.writeln();
      }

      buffer.writeln("}");
      buffer.writeln();
    }

    return buffer.toString();
  }
}

String extractMethodParams(String stepText) {
  final params = <String>[];
  final regex = RegExp(r'<(\w+)>');
  final matches = regex.allMatches(stepText);

  for (var match in matches) {
    final paramName = match.group(1)!;
    params.add('String ${paramName.snakeCaseToCamelCase}');
  }

  return params.join(', ');
}
