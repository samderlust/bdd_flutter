import '../../domain/background.dart';
import '../../domain/examples_table.dart';
import '../../domain/feature.dart';
import '../../domain/feature_files.dart';
import '../../domain/rule.dart';
import '../../domain/scenario.dart';
import '../../domain/step.dart';
import '../../domain/value_type.dart';
import '../../extensions/string_x.dart';
import '../steps/column_types.dart';
import '../steps/steps_catalog.dart';
import 'generated_header.dart';
import 'scenario_settings.dart';
import 'step_arguments.dart';

/// Generates `.bdd_test.dart` files: one test per scenario, and one test
/// per example row of a Scenario Outline.
///
/// Every test creates a fresh steps object, runs the Background, then the
/// scenario's steps. This file is rewritten on every build.
class TestFileBuilder {
  /// When a scenario has no `@unitTest`/`@widgetTest`, generate `testWidgets`.
  final bool widgetTestsByDefault;

  const TestFileBuilder({this.widgetTestsByDefault = true});

  /// Builds the test file for [files]'s feature.
  String build(FeatureFiles files, StepsCatalog catalog) {
    final writer = _TestWriter(files, catalog, widgetTestsByDefault);
    final feature = files.feature;
    final buffer = StringBuffer(generatedHeader('${feature.fileName}.feature'))
      ..writeln("import 'package:flutter_test/flutter_test.dart';\n")
      ..writeln("import '${files.stepsFileName}';\n")
      ..writeln('void main() {')
      ..writeln('  group(${feature.name.toDartStringLiteral}, () {');
    for (final scenario in feature.scenarios) {
      writer.writeScenario(buffer, scenario);
    }
    for (final rule in feature.rules) {
      buffer.writeln('  group(${'Rule: ${rule.name}'.toDartStringLiteral}, () {');
      for (final scenario in rule.scenarios) {
        writer.writeScenario(buffer, scenario, rule: rule);
      }
      buffer.writeln('  });');
    }
    buffer
      ..writeln('  });')
      ..writeln('}');
    return buffer.toString();
  }

  /// Whether any scenario of [feature] becomes a widget test, so the steps
  /// class needs a `tester` field.
  bool needsTester(Feature feature) {
    bool isWidget(Rule? rule, Scenario s) =>
        !ScenarioSettings.of(feature, rule, s, widgetTestsByDefault: widgetTestsByDefault).isUnitTest;
    return feature.scenarios.any((s) => isWidget(null, s)) ||
        feature.rules.any((r) => r.scenarios.any((s) => isWidget(r, s)));
  }
}

/// Writes the tests of one feature.
class _TestWriter {
  final FeatureFiles files;
  final StepsCatalog catalog;
  final bool widgetTestsByDefault;

  _TestWriter(this.files, this.catalog, this.widgetTestsByDefault);

  void writeScenario(StringBuffer buffer, Scenario scenario, {Rule? rule}) {
    final settings = ScenarioSettings.of(files.feature, rule, scenario, widgetTestsByDefault: widgetTestsByDefault);
    if (!scenario.isOutline) {
      _writeTest(buffer, scenario.name, settings, settings.tagsFor(), settings.skip, () {
        _writeSteps(buffer, scenario, rule, const {}, const {});
      });
      return;
    }
    final columns = columnTypes(scenario.examples);
    buffer.writeln('  group(${scenario.name.toDartStringLiteral}, () {');
    for (final table in scenario.examples) {
      for (var i = 0; i < table.rows.length; i++) {
        final row = table.rows[i];
        _writeTest(buffer, _rowName(table, i), settings, settings.tagsFor(table), settings.skipFor(table), () {
          _writeSteps(buffer, scenario, rule, row, columns);
        });
      }
    }
    buffer.writeln('  });');
  }

  /// `Small orders #1 (item: apple, quantity: 1)`.
  String _rowName(ExamplesTable table, int index) {
    final label = table.name.isEmpty ? 'Example' : table.name;
    final values = table.rows[index].entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return '$label #${index + 1} ($values)';
  }

  void _writeTest(
    StringBuffer buffer,
    String name,
    ScenarioSettings settings,
    List<String> tags,
    bool skip,
    void Function() writeBody,
  ) {
    final literal = name.toDartStringLiteral;
    if (settings.isUnitTest) {
      buffer
        ..writeln('  test($literal, () async {')
        ..writeln('    final steps = ${files.stepsClass}();');
    } else {
      buffer
        ..writeln('  testWidgets($literal, (tester) async {')
        ..writeln('    final steps = ${files.stepsClass}()..tester = tester;');
    }
    writeBody();
    buffer.writeln('  }${_options(tags, skip)});');
  }

  String _options(List<String> tags, bool skip) {
    final options = [
      if (tags.isNotEmpty) 'tags: [${tags.map((t) => t.toDartStringLiteral).join(', ')}]',
      if (skip) 'skip: true',
    ];
    return options.isEmpty ? '' : ', ${options.join(', ')}';
  }

  void _writeSteps(
    StringBuffer buffer,
    Scenario scenario,
    Rule? rule,
    Map<String, String> row,
    Map<String, ValueType> columns,
  ) {
    _writeBackground(buffer, files.feature.background, 'Background');
    _writeBackground(buffer, rule?.background, 'Rule background');
    if (files.feature.background != null || rule?.background != null) {
      buffer.writeln('    // Scenario');
    }
    for (final step in scenario.steps) {
      _writeStep(buffer, step, row: row, columns: columns);
    }
  }

  void _writeBackground(StringBuffer buffer, Background? background, String label) {
    if (background == null) return;
    final description = background.description.isEmpty ? '' : ': ${background.description}';
    buffer.writeln('    // $label$description');
    for (final step in background.steps) {
      _writeStep(buffer, step);
    }
  }

  void _writeStep(
    StringBuffer buffer,
    Step step, {
    Map<String, String> row = const {},
    Map<String, ValueType> columns = const {},
  }) {
    final pattern = catalog.patternOf(step, columns: columns);
    final method = catalog.methodOf(files.feature, pattern);
    final arguments = stepArguments(step, pattern, row: row).join(', ');
    buffer
      ..writeln('    // ${step.message}')
      ..writeln('    await steps.${method.name}($arguments);');
  }
}
