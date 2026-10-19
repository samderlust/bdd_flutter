import '../../domain/feature.dart';
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
    final buffer = StringBuffer(generatedHeader('${files.feature.fileName}.feature'));
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
    for (final method in catalog.methodsFor(files.feature)) {
      _writeMethod(buffer, method, _otherFeatures(catalog, method, files.feature.path));
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  /// File names of the other features that use [method].
  List<String> _otherFeatures(StepsCatalog catalog, StepMethod method, String path) {
    return [
      for (final other in catalog.featuresUsing(method))
        if (other != path) other.split(RegExp(r'[/\\]')).last,
    ];
  }

  void _writeMethod(StringBuffer buffer, StepMethod method, List<String> otherFeatures) {
    for (final message in method.stepMessages) {
      buffer.writeln('  /// `$message`');
    }
    if (otherFeatures.isNotEmpty) {
      buffer
        ..writeln('  ///')
        ..writeln('  /// Also used by ${otherFeatures.join(', ')}.');
    }
    buffer.writeln('  ${method.signature};\n');
  }
}
