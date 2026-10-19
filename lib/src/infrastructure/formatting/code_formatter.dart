import 'dart:io';

/// Formats files bdd_flutter has written.
abstract interface class CodeFormatter {
  /// Formats the files at [paths] in place. Never throws: a failure is
  /// reported and the files stay as written.
  Future<void> formatFiles(List<String> paths);
}

/// Runs the SDK's own `dart format`, so bdd_flutter needs no dependency on
/// `dart_style` or `analyzer`.
///
/// The files live inside the user's package, so `dart format` picks the
/// style and page width that package uses.
class DartFormatCommand implements CodeFormatter {
  const DartFormatCommand();

  @override
  Future<void> formatFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      final result = await Process.run(_dartExecutable, ['format', ...paths]);
      if (result.exitCode == 0) return;
      stderr.writeln('bdd_flutter: dart format failed; files are left unformatted.\n${result.stderr}');
    } on ProcessException catch (e) {
      stderr.writeln('bdd_flutter: could not run dart format; files are left unformatted. ${e.message}');
    }
  }

  /// The `dart` running bdd_flutter, not whichever one is first on `PATH`.
  /// Under `dart test` or an AOT snapshot that is not `dart`, so fall back
  /// to `PATH`.
  String get _dartExecutable {
    final executable = Platform.resolvedExecutable;
    final name = executable.split(RegExp(r'[/\\]')).last;
    return name == 'dart' || name == 'dart.exe' ? executable : 'dart';
  }
}

/// Leaves files as written; used in tests.
class NoFormatting implements CodeFormatter {
  const NoFormatting();

  @override
  Future<void> formatFiles(List<String> paths) async {}
}
