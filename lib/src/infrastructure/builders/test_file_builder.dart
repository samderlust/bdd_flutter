import '../../constraints/file_constraint.dart';
import '../../domain/feature.dart';
import '../../domain/scenario.dart';
import '../../domain/step.dart';
import '../../extensions/string_x.dart';

/// Generates `.bdd_test.dart` files containing test orchestration code.
///
/// The test file instantiates scenario classes and calls their step methods.
/// This file is always fully regenerated — it contains no user code.
class TestFileBuilder {
  /// Builds a test file for all scenarios in [feature].
  Future<String> buildTestFile(
    Feature feature, {
    String scenarioSuffix = 'Scenario',
  }) async {
    final buffer = StringBuffer();

    buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    buffer.writeln("import '${feature.fileName}${FileConstraint.generatedScenarios}';");
    buffer.writeln();

    buffer.writeln("void main() {");
    buffer.writeln("  group('${feature.name}', () {");

    for (var scenario in feature.scenarios) {
      final className = scenario.classNameWithSuffix(scenarioSuffix);
      final isUnitTest = scenario.isUnitTestWithFeature(feature.decorators);
      final testFunction = isUnitTest ? 'test' : 'testWidgets';

      if (isUnitTest) {
        buffer.writeln("    $testFunction('${scenario.name}', () async {");
      } else {
        buffer.writeln("    $testFunction('${scenario.name}', (tester) async {");
      }

      buffer.writeln("      final scenario = $className();");

      if (feature.background != null) {
        buffer.writeln("      final background = ${feature.name.name}Background();");
        buffer.writeln("      //Background: ${feature.background!.description}");
        for (var step in feature.background!.steps) {
          final methodName = step.methodName;
          buffer.writeln("      await background.$methodName();");
        }
      }

      buffer.writeln("      //Scenario: ${scenario.name}");

      if (scenario.examples != null && scenario.examples!.isNotEmpty) {
        buffer.writeln("      final examples = [");

        for (var example in scenario.examples!) {
          buffer.write("        {");
          for (var entry in example.entries) {
            buffer.write("'${entry.key.snakeCaseToCamelCase}': '${entry.value}',");
          }
          buffer.write("},");
          buffer.writeln();
        }
        buffer.writeln("      ];");

        final exampleKeys = scenario.examples!.first.keys.toList();
        buffer.writeln("      for (var example in examples) {");

        for (var step in scenario.steps) {
          final params = <String>[];
          for (var key in exampleKeys) {
            if (step.text.contains('<$key>')) {
              params.add("example['${key.snakeCaseToCamelCase}']!");
            }
          }

          buffer.writeln(_generateStepCall(step, isUnitTest, params));
        }
        buffer.writeln("      }");
      } else {
        for (var step in scenario.steps) {
          buffer.writeln(_generateStepCall(step, isUnitTest, []));
        }
      }
      buffer.writeln("    });");
    }

    buffer.writeln("  });");
    buffer.writeln("}");

    return buffer.toString();
  }
}

String _generateStepCall(Step step, bool isUnitTest, List<String> params) {
  final methodName = step.methodName;
  return '''
      // ${step.message}
      await scenario.$methodName(${isUnitTest ? '' : 'tester'}${params.isNotEmpty ? "${isUnitTest ? '' : ','} ${params.join(', ')}" : ''});''';
}
