import '../../constraints/file_constraint.dart';
import '../../domain/decorator.dart';
import '../../domain/feature.dart';
import '../../domain/scenario.dart';
import '../../domain/step.dart';
import '../../extensions/string_x.dart';

class TestFileBuilder {
  Future<String> buildTestFile(Feature feature) async {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    //add reporter import if needed
    if (feature.decorators.hasEnableReporter) {
      buffer.writeln("import 'package:bdd_flutter/bdd_flutter.dart';");
    }

    buffer.writeln("import '${feature.fileName}${FileConstraint.generatedScenarios}';");
    buffer.writeln();

    buffer.writeln("void main() {");
    //add reporter initialization if needed
    if (feature.decorators.hasEnableReporter) {
      buffer.writeln("  final reporter = BDDTestReporter(featureName: '${feature.name}');");
      buffer.writeln("  setUpAll(() {");
      buffer.writeln("    reporter.testStarted(); // start recording");
      buffer.writeln("  });");
      buffer.writeln("  tearDownAll(() {");
      buffer.writeln("    reporter.testFinished(); // stop recording");
      buffer.writeln("    reporter.printReport(); // print report");
      buffer.writeln("    //reporter.saveReportToFile(); //uncomment to save report to file");
      buffer.writeln("  });");
    }

    buffer.writeln("  group('${feature.name}', () {");

    for (var scenario in feature.scenarios) {
      final className = scenario.className;
      final isUnitTest = scenario.isUnitTest;
      final testFunction = isUnitTest ? 'test' : 'testWidgets';

      // Generate one test case per scenario
      if (isUnitTest) {
        buffer.writeln("    $testFunction('${scenario.name}', () async {");
      } else {
        buffer.writeln("    $testFunction('${scenario.name}', (tester) async {");
      }

      // Instantiate scenario and background
      buffer.writeln("      final scenario = $className();");

      if (feature.background != null) {
        buffer.writeln("      final background = ${feature.name}Background();");
        buffer.writeln("      //Background: ${feature.background!.description}");
        for (var step in feature.background!.steps) {
          final methodName = step.methodName;
          buffer.writeln("      await background.$methodName();");
        }
      }

      buffer.writeln("      //Scenario: ${scenario.name}");

      //add start scenario if needed
      if (feature.decorators.hasEnableReporter) {
        buffer.writeln("      reporter.startScenario('${scenario.name}');");
      }

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

        // Get the keys from the first example for parameter generation
        final exampleKeys = scenario.examples!.first.keys.toList();
        buffer.writeln("      for (var example in examples) {");

        for (var step in scenario.steps) {
          final params = <String>[];
          for (var key in exampleKeys) {
            if (step.text.contains('<$key>')) {
              params.add("example['${key.snakeCaseToCamelCase}']!");
            }
          }

          buffer.writeln(_generateStepCall(
            step,
            feature.decorators.hasEnableReporter,
            isUnitTest,
            params,
          ));
        }
        buffer.writeln("      }");
      } else {
        // For scenarios without examples, just call all steps once
        for (var step in scenario.steps) {
          buffer.writeln(_generateStepCall(
            step,
            feature.decorators.hasEnableReporter,
            isUnitTest,
            [],
          ));
        }
      }
      buffer.writeln("    });");
    }

    buffer.writeln("  });");
    buffer.writeln("}");

    return buffer.toString();
  }
}

String _generateStepCall(
  Step step,
  bool withReporter,
  bool isUnitTest,
  List<String> params,
) {
  final methodName = step.methodName;
  if (withReporter) {
    return '''
      await reporter.guard(
        () => scenario.$methodName(${isUnitTest ? '' : 'tester'}${params.isNotEmpty ? "${isUnitTest ? '' : ','} ${params.join(', ')}" : ''}),
        '${step.message}',
      );''';
  } else {
    return '''
      // ${step.message}
      await scenario.$methodName(${isUnitTest ? '' : 'tester'}${params.isNotEmpty ? "${isUnitTest ? '' : ','} ${params.join(', ')}" : ''});''';
  }
}
