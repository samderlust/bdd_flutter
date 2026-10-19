import '../../domain/feature_files.dart';
import '../../domain/step_method.dart';
import '../../extensions/string_x.dart';
import '../steps/steps_catalog.dart';

/// Code carried into a new steps file, e.g. from a 1.x scenarios file.
class StepsStubContent {
  /// Extra import lines, written as-is.
  final List<String> imports;

  /// Top-level declarations placed between the imports and the class.
  final List<String> topLevel;

  /// Field declarations placed at the top of the class.
  final List<String> fields;

  /// Method bodies by method name, replacing the default body.
  final Map<String, String> bodies;

  const StepsStubContent({
    this.imports = const [],
    this.topLevel = const [],
    this.fields = const [],
    this.bodies = const {},
  });
}

/// Generates the steps file the user owns, e.g. `cart_steps.dart`.
///
/// bdd_flutter writes this file once, when it does not exist yet, and
/// never touches it again. Every method throws until it is implemented.
class StepsStubBuilder {
  const StepsStubBuilder();

  /// Builds a steps class for [files] that implements the contract.
  ///
  /// [additionalImports] come from the config; [content] carries code
  /// migrated from 1.x.
  String build(
    FeatureFiles files,
    StepsCatalog catalog, {
    required bool needsTester,
    List<String> additionalImports = const [],
    StepsStubContent content = const StepsStubContent(),
  }) {
    final buffer = StringBuffer();
    _writeImports(buffer, files, additionalImports, content.imports);
    for (final declaration in content.topLevel) {
      buffer.writeln('$declaration\n');
    }
    buffer
      ..writeln('/// The steps of the feature "${files.feature.name}".')
      ..writeln('class ${files.stepsClass} implements ${files.contractClass} {');
    if (needsTester) {
      buffer.writeln('  @override\n  late WidgetTester tester;\n');
    }
    for (final field in content.fields) {
      buffer.writeln('  $field\n');
    }
    for (final method in catalog.methods) {
      _writeMethod(buffer, method, content.bodies[method.name]);
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  void _writeImports(StringBuffer buffer, FeatureFiles files, List<String> configImports, List<String> extra) {
    final imports = <String>{
      "import 'package:flutter_test/flutter_test.dart';",
      for (final path in configImports) "import '$path';",
      ...extra,
    };
    imports.forEach(buffer.writeln);
    buffer.writeln("\nimport '${files.contractFileName}';\n");
  }

  void _writeMethod(StringBuffer buffer, StepMethod method, String? body) {
    final todo = method.stepMessages.first.toDartStringLiteral;
    buffer
      ..writeln('  @override')
      ..writeln('  ${method.signature} async {')
      ..writeln(body ?? '    throw UnimplementedError($todo);')
      ..writeln('  }\n');
  }
}
