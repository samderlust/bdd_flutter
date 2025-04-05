import 'package:build/build.dart';

import '../domain/feature.dart';
import '../domain/scenario.dart';
import '../extensions/string_x.dart';

class BDDTestFileBuilder {
  Future<void> build(BuildStep buildStep, Feature feature) async {
    final inputId = buildStep.inputId;
    final testOutputId = inputId.changeExtension('_test.dart');

    final testContent = await buildTestFile(feature);
    await buildStep.writeAsString(testOutputId, testContent);
  }

  Future<String> buildTestFile(Feature feature) async {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    buffer.writeln("import  '${feature.name.toLowerCase()}_scenarios.dart';");
    buffer.writeln();

    buffer.writeln("void main() {");
    buffer.writeln("  group('${feature.name}', () {");

    for (var scenario in feature.scenarios) {
      final className = scenario.name.toClassName;

      final isUnitTest = scenario.isUnitTest;

      final testFunction = isUnitTest ? 'test' : 'testWidgets';

      // Generate one test case per scenario
      if (isUnitTest) {
        buffer.writeln("    $testFunction('${scenario.name}', () async {");
      } else {
        buffer
            .writeln("    $testFunction('${scenario.name}', (tester) async {");
      }

      if (scenario.examples != null && scenario.examples!.isNotEmpty) {
        // First, call all setup steps (Given steps) once
        for (var step in scenario.steps) {
          if (step.keyword == 'Given') {
            final methodName = step.text.toMethodName;
            if (isUnitTest) {
              buffer.writeln("      await $className.$methodName();");
            } else {
              buffer.writeln("      await $className.$methodName(tester);");
            }
          }
        }

        // Then for each example, call the non-setup steps with the example values
        for (var example in scenario.examples!) {
          buffer.writeln(
            "      // Example with values: ${example.values.join(', ')}",
          );
          for (var step in scenario.steps) {
            if (step.keyword != 'Given') {
              // Skip Given steps as they're already called
              final methodName = step.text.toMethodName;
              final params = <String>[];

              // Extract parameters from the example values
              example.forEach((key, value) {
                if (step.text.contains('<$key>')) {
                  params.add("'$value'");
                }
              });

              if (!isUnitTest) {
                buffer.writeln(
                  "      await $className.$methodName(tester${params.isNotEmpty ? ', ${params.join(', ')}' : ''});",
                );
              } else {
                buffer.writeln(
                  "      await $className.$methodName(${params.isNotEmpty ? params.join(', ') : ''});",
                );
              }
            }
          }
        }
      } else {
        // For scenarios without examples, just call all steps once
        for (var step in scenario.steps) {
          final methodName = step.text.toMethodName;
          if (!isUnitTest) {
            buffer.writeln("      await $className.$methodName(tester);");
          } else {
            buffer.writeln("      await $className.$methodName();");
          }
        }
      }
      buffer.writeln("    });");
    }

    buffer.writeln("  });");
    buffer.writeln("}");

    return buffer.toString();
  }
}
