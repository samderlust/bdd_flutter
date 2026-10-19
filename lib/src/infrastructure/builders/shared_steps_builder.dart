import '../../domain/shared_files.dart';
import '../../domain/step_method.dart';
import '../../extensions/string_x.dart';

/// Generates `shared_steps.dart`, the user's mixin for steps used by more
/// than one feature. It is created once, the first time steps are shared,
/// and never touched again.
///
/// The mixin implements no generated interface: each feature contract
/// already declares the steps its feature uses, so a feature steps class
/// that mixes it in is checked against its own contract. A step becoming
/// shared later therefore never breaks a class that does not use it.
class SharedStepsBuilder {
  const SharedStepsBuilder();

  /// The mixin with [methods], each throwing until written. With
  /// [needsTester], it declares the `tester` its steps can use; the
  /// classes that mix it in provide it.
  String buildMixin(
    SharedFiles files,
    List<StepMethod> methods, {
    required bool needsTester,
    List<String> additionalImports = const [],
  }) {
    final buffer = StringBuffer("import 'package:flutter_test/flutter_test.dart';\n");
    for (final path in additionalImports) {
      buffer.writeln("import '$path';");
    }
    buffer
      ..writeln('\n/// Steps used by more than one feature, written once.')
      ..writeln('///')
      ..writeln('/// Feature steps classes mix this in with `with ${files.mixinName}`. Keep the')
      ..writeln('/// state these steps share in fields here; every test gets a fresh object.')
      ..writeln('mixin ${files.mixinName} {');
    if (needsTester) {
      buffer.writeln(
        '  /// The tester of the running widget test, provided by the steps class.\n  WidgetTester get tester;\n',
      );
    }
    for (final method in methods) {
      for (final message in method.stepMessages) {
        buffer.writeln('  /// `$message`');
      }
      buffer
        ..writeln('  ${method.signature} async {')
        ..writeln('    throw UnimplementedError(${method.stepMessages.first.toDartStringLiteral});')
        ..writeln('  }\n');
    }
    buffer.writeln('}');
    return buffer.toString();
  }
}
