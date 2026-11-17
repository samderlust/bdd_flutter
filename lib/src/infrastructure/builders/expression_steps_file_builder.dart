import '../../domain/feature.dart';
import '../../domain/feature_files.dart';
import '../migration/steps_source_rewriter.dart';

/// Generates a new `_steps.dart` file for `steps_mode: expressions`: the
/// steps class with no steps yet, ready for `@Given`/`@When`/`@Then` methods. It is created
/// once, when the feature has no steps file, and never touched again.
class ExpressionStepsFileBuilder {
  const ExpressionStepsFileBuilder();

  /// The steps file for [files]'s feature.
  ///
  /// [sharedMixin] and [sharedImport] make the class mix in the shared
  /// steps; [needsTester] adds the `tester` field widget tests set,
  /// overriding the mixin's when [mixinDeclaresTester].
  String build(
    FeatureFiles files, {
    required bool needsTester,
    String? sharedMixin,
    String? sharedImport,
    bool mixinDeclaresTester = false,
    List<String> additionalImports = const [],
  }) {
    final buffer = StringBuffer("import 'package:bdd_flutter/bdd_flutter.dart';\n");
    if (needsTester) buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    for (final path in additionalImports) {
      final hidden = StepsSourceRewriter.clashingNames[path];
      buffer.writeln("import '$path'${hidden == null ? '' : ' hide ${hidden.join(', ')}'};");
    }
    if (sharedImport != null) buffer.writeln("\nimport '$sharedImport';");
    buffer
      ..writeln('\n/// The steps of the feature "${files.feature.name}".')
      ..writeln('///')
      ..writeln('/// Write one method per step, annotated with `@Given`, `@When`, `@Then` or')
      ..writeln('/// `@StepDefinition` and a Cucumber Expression, e.g.')
      ..writeln("/// `@When('I add {int} {string}')`. `build` matches every step of")
      ..writeln('/// ${files.feature.fileName}.feature against them.')
      ..writeln('class ${files.stepsClass}${sharedMixin == null ? '' : ' with $sharedMixin'} {');
    if (needsTester) {
      buffer.writeln('  ${mixinDeclaresTester ? '@override\n  ' : ''}late WidgetTester tester;');
    }
    buffer.writeln('}');
    return buffer.toString();
  }
}
