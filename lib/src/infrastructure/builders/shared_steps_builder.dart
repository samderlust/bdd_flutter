import '../../domain/shared_files.dart';
import '../../domain/step_method.dart';
import '../../extensions/string_x.dart';
import '../steps/steps_catalog.dart';
import 'generated_header.dart';

/// Generates the files for steps used by more than one feature:
/// - [buildContract]: `shared.bdd_steps.dart`, rewritten on every build;
/// - [buildMixin]: `shared_steps.dart`, created once for the user.
///
/// Feature contracts still declare every step their feature uses, so a
/// feature steps class compiles whether it mixes in the shared steps or
/// implements them itself.
class SharedStepsBuilder {
  const SharedStepsBuilder();

  /// The shared contract: every method of [catalog] used by two or more
  /// features, with a `tester` field when [needsTester] is true.
  String buildContract(SharedFiles files, StepsCatalog catalog, {required bool needsTester}) {
    final buffer = StringBuffer(generatedHeader('the .feature files in ${files.testDir}'));
    if (needsTester) buffer.writeln("import 'package:flutter_test/flutter_test.dart';\n");
    buffer
      ..writeln('/// Steps used by more than one feature.')
      ..writeln('///')
      ..writeln('/// Implement them once in `mixin ${files.mixinName}` and mix it into the')
      ..writeln('/// feature steps classes.')
      ..writeln('abstract interface class ${files.contractClass} {');
    if (needsTester) {
      buffer
        ..writeln('  /// The tester of the running widget test, set before its first step.')
        ..writeln('  abstract WidgetTester tester;\n');
    }
    for (final method in catalog.sharedMethods) {
      _writeContractMethod(buffer, method, catalog.featuresUsing(method));
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  /// The user's shared mixin, with every method throwing until written.
  String buildMixin(SharedFiles files, StepsCatalog catalog, {List<String> additionalImports = const []}) {
    final buffer = StringBuffer("import 'package:flutter_test/flutter_test.dart';\n");
    for (final path in additionalImports) {
      buffer.writeln("import '$path';");
    }
    buffer
      ..writeln("\nimport 'shared.bdd_steps.dart';\n")
      ..writeln('/// Steps used by more than one feature. Feature steps classes mix this')
      ..writeln('/// in with `with ${files.mixinName}`; keep the state these steps share here.')
      ..writeln('mixin ${files.mixinName} implements ${files.contractClass} {');
    for (final method in catalog.sharedMethods) {
      buffer
        ..writeln('  @override')
        ..writeln('  ${method.signature} async {')
        ..writeln('    throw UnimplementedError(${method.stepMessages.first.toDartStringLiteral});')
        ..writeln('  }\n');
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  void _writeContractMethod(StringBuffer buffer, StepMethod method, List<String> features) {
    for (final message in method.stepMessages) {
      buffer.writeln('  /// `$message`');
    }
    final names = features.map((f) => f.split(RegExp(r'[/\\]')).last).join(', ');
    buffer
      ..writeln('  ///')
      ..writeln('  /// Used by $names.')
      ..writeln('  ${method.signature};\n');
  }
}
