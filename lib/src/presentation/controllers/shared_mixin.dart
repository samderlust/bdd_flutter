import 'dart:io';

import '../../domain/shared_files.dart';
import '../../domain/step_method.dart';
import 'steps_file_check.dart';

/// What the user's shared steps mixin provides.
class SharedMixin {
  /// Where the mixin lives and what it is called.
  final SharedFiles files;

  /// The parameter types of each step method the mixin implements, by name.
  final Map<String, List<String>> signatures;

  /// Whether the mixin declares `tester`, so classes using it must have one.
  final bool declaresTester;

  const SharedMixin(this.files, {required this.signatures, required this.declaresTester});

  /// The names of the step methods the mixin implements.
  Set<String> get methods => signatures.keys.toSet();

  /// Whether the mixin implements [method] with the same parameter types.
  bool provides(StepMethod method) {
    final types = signatures[method.name];
    return types != null && _sameTypes(types, method.parameters.map((p) => p.dartType.replaceAll(' ', '')).toList());
  }

  /// Whether the mixin has a method named like [method] but with other
  /// parameter types, which a class mixing it in could not also declare.
  bool clashesWith(StepMethod method) => signatures.containsKey(method.name) && !provides(method);

  static bool _sameTypes(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Reads the mixin at [files], or returns `null` when it does not exist.
  static SharedMixin? read(SharedFiles files) {
    final file = File(files.stepsPath);
    if (!file.existsSync()) return null;
    final source = file.readAsStringSync();
    return SharedMixin(
      files,
      signatures: definedSignatures(source),
      declaresTester: RegExp(r'WidgetTester\s+(get\s+)?tester\b').hasMatch(source),
    );
  }
}
