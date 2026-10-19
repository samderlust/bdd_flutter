import '../../domain/feature_files.dart';
import '../../domain/step_method.dart';
import '../steps/steps_catalog.dart';
import 'generated_header.dart';

/// Generates the `.bdd_steps.dart` file: an interface with one method per
/// distinct step of the feature.
///
/// This file is rewritten on every build. The user implements the interface
/// in their own steps file, so the analyzer reports steps that are missing
/// or no longer used.
class StepsContractBuilder {
  const StepsContractBuilder();

  /// Builds the contract for [files], with a `tester` field when
  /// [needsTester] is true.
  String build(FeatureFiles files, StepsCatalog catalog, {required bool needsTester}) {
    final buffer = StringBuffer(generatedHeader(files.feature));
    if (needsTester) {
      buffer.writeln("import 'package:flutter_test/flutter_test.dart';\n");
    }
    buffer
      ..writeln('/// The steps of the feature "${files.feature.name}".')
      ..writeln('///')
      ..writeln('/// Implement them in `${files.stepsFileName}`.')
      ..writeln('abstract interface class ${files.contractClass} {');
    if (needsTester) {
      buffer
        ..writeln('  /// The tester of the running widget test, set before its first step.')
        ..writeln('  abstract WidgetTester tester;\n');
    }
    for (final method in catalog.methods) {
      _writeMethod(buffer, method);
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  void _writeMethod(StringBuffer buffer, StepMethod method) {
    for (final message in method.stepMessages) {
      buffer.writeln('  /// `$message`');
    }
    buffer.writeln('  ${method.signature};\n');
  }
}
