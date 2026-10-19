import 'dart:convert';
import 'dart:io';

import 'bdd_report_formatter.dart';
import 'test_event_collector.dart';

/// Runs every test in [testDir] with `flutter test --machine` and prints a
/// report: BDD tests grouped by feature, then other tests by file.
class BDDTestRunner {
  final BDDReportFormatter _formatter;
  final String testDir;

  BDDTestRunner({BDDReportFormatter? formatter, this.testDir = 'test/'})
    : _formatter = formatter ?? BDDReportFormatter.forStdout();

  /// Runs the tests and prints the report. Returns `flutter test`'s exit
  /// code (0 when everything passed).
  Future<int> run() async {
    final files = _testFiles();
    if (files.isEmpty) {
      stdout.writeln('No test files found in "$testDir".');
      return 0;
    }
    final bddCount = files.where((f) => f.endsWith('.bdd_test.dart')).length;
    stdout.writeln('Running ${files.length} test file(s), $bddCount from .feature files...');

    final started = DateTime.now();
    final collector = TestEventCollector(rootPath: Directory.current.path);
    final process = await Process.start('flutter', ['test', '--machine', ...files]);
    final errors = process.stderr.transform(utf8.decoder).join();
    await process.stdout.transform(utf8.decoder).transform(const LineSplitter()).forEach(collector.addLine);
    final exitCode = await process.exitCode;

    if (collector.results.isEmpty && exitCode != 0) stdout.writeln(await errors);
    stdout.write(_formatter.format(collector.results, elapsed: DateTime.now().difference(started)));
    return exitCode;
  }

  List<String> _testFiles() {
    final directory = Directory(testDir);
    if (!directory.existsSync()) return const [];
    return directory.listSync(recursive: true).map((f) => f.path).where((p) => p.endsWith('_test.dart')).toList()
      ..sort();
  }
}
