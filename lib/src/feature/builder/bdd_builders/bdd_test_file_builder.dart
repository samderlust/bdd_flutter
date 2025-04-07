import 'package:bdd_flutter/src/feature/builder/domain/decorator.dart';
import 'package:build/build.dart';

import '../domain/feature.dart';
import '../domain/scenario.dart';
import '../domain/step.dart';
import '../../../extensions/string_x.dart';

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
    //add reporter import if needed
    if (feature.decorators.hasEnableReporter) {
      buffer.writeln("import 'package:bdd_flutter/bdd_flutter.dart';");
    }

    buffer.writeln("import  '${feature.name.toLowerCase()}_scenarios.dart';");
    buffer.writeln();

    buffer.writeln("void main() {");
    //add reporter initialization if needed
    if (feature.decorators.hasEnableReporter) {
      buffer.writeln(
          "  final reporter = BDDTestReporter(featureName: '${feature.name}');");
      buffer.writeln("  setUpAll(() {");
      buffer.writeln("    reporter.testStarted(); // start recording");
      buffer.writeln("  });");
      buffer.writeln("  tearDownAll(() {");
      buffer.writeln("    reporter.testFinished(); // stop recording");
      buffer.writeln("    reporter.printReport(); // print report");
      buffer.writeln(
          "    //reporter.saveReportToFile(); //uncomment to save report to file");
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
        buffer
            .writeln("    $testFunction('${scenario.name}', (tester) async {");
      }

      //add start scenario if needed
      if (feature.decorators.hasEnableReporter) {
        buffer.writeln("\t\t\t reporter.startScenario('${scenario.name}');");
      }

      if (scenario.examples != null && scenario.examples!.isNotEmpty) {
        // For each example, call all steps with the example values
        for (var example in scenario.examples!) {
          buffer.writeln(
            "      // Example with values: ${example.values.join(', ')}",
          );
          for (var step in scenario.steps) {
            final params = <String>[];

            // Extract parameters from the example values
            example.forEach((key, value) {
              if (step.text.contains('<$key>')) {
                params.add("'${value.snakeCaseToCamelCase}'");
              }
            });

            buffer.writeln(
              _generateTestFunction(
                buffer,
                testFunction,
                scenario.name,
                className,
                step,
                feature.decorators.hasEnableReporter,
                isUnitTest,
                params,
              ),
            );
          }
        }
      } else {
        // For scenarios without examples, just call all steps once
        for (var step in scenario.steps) {
          buffer.writeln(_generateTestFunction(
            buffer,
            testFunction,
            scenario.name,
            className,
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

String _generateTestFunction(
  StringBuffer buffer,
  String testFunction,
  String scenarioName,
  String className,
  Step step,
  bool withReporter,
  bool isUnitTest,
  List<String> params,
) {
  final methodName = step.text.toMethodName;
  if (withReporter) {
    return ('''\tawait reporter.guard(() => 
    $className.$methodName(${isUnitTest ? '' : 'tester,'}${params.isNotEmpty ? params.join(', ') : ''}), 
    '${step.message}',);''');
  } else {
    return ("\tawait $className.$methodName(${isUnitTest ? '' : 'tester,'}${params.isNotEmpty ? params.join(', ') : ''});");
  }
}
