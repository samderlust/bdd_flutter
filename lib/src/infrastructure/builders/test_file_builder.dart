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
          buffer.writeln("      await background.$methodName(${_stepArgs(step).join(', ')});");
        }
      }

      buffer.writeln("      //Scenario: ${scenario.name}");

      if (scenario.examples != null && scenario.examples!.isNotEmpty) {
        final columns = scenario.examples!.expand((e) => e.keys).toSet();
        buffer.writeln("      final examples = [");

        for (var example in scenario.examples!) {
          buffer.write("        {");
          for (var column in columns) {
            // A column missing from this row's Examples block keeps its
            // `<column>` text, as Gherkin leaves unmatched placeholders as-is.
            final value = example[column] ?? '<$column>';
            buffer.write("'${column.snakeCaseToCamelCase}': ${value.toDartStringLiteral},");
          }
          buffer.write("},");
          buffer.writeln();
        }
        buffer.writeln("      ];");

        buffer.writeln("      for (var example in examples) {");

        for (var step in scenario.steps) {
          buffer.writeln(_generateStepCall(step, isUnitTest, _stepArgs(step, exampleColumns: columns)));
        }
        buffer.writeln("      }");
      } else {
        for (var step in scenario.steps) {
          buffer.writeln(_generateStepCall(step, isUnitTest, _stepArgs(step)));
        }
      }
      buffer.writeln("    });");
    }

    buffer.writeln("  });");
    buffer.writeln("}");

    return buffer.toString();
  }
}

/// Arguments for a step call, in the same order as
/// [StepX.parameterDeclarations]: placeholders, then doc string, then data table.
///
/// Placeholders matching one of [exampleColumns] are read from the current
/// example row, including `<column>` inside doc strings and tables. Any other
/// placeholder is passed as its literal `<name>` text, so every declared
/// parameter always receives an argument.
List<String> _stepArgs(Step step, {Set<String> exampleColumns = const {}}) {
  final docString = step.docString;
  final dataTable = step.dataTable;
  return [
    for (final name in step.placeholders)
      exampleColumns.contains(name) ? _exampleValue(name) : '<$name>'.toDartStringLiteral,
    if (docString != null) _literal(docString, exampleColumns),
    if (dataTable != null) _tableLiteral(dataTable, exampleColumns),
  ];
}

String _exampleValue(String column) => "example['${column.snakeCaseToCamelCase}']!";

/// A Dart string literal for [value], with `<column>` replaced by the
/// current example row's value for every column in [exampleColumns].
String _literal(String value, Set<String> exampleColumns) {
  final buffer = StringBuffer(value.toDartStringLiteral);
  for (final column in exampleColumns) {
    if (!value.contains('<$column>')) continue;
    buffer.write(".replaceAll('<$column>', ${_exampleValue(column)})");
  }
  return buffer.toString();
}

String _tableLiteral(List<List<String>> rows, Set<String> exampleColumns) {
  final rowLiterals = rows.map((row) => '[${row.map((cell) => _literal(cell, exampleColumns)).join(', ')}]');
  return '[${rowLiterals.join(', ')}]';
}

String _generateStepCall(Step step, bool isUnitTest, List<String> params) {
  final methodName = step.methodName;
  return '''
      // ${step.message}
      await scenario.$methodName(${[if (!isUnitTest) 'tester', ...params].join(', ')});''';
}
