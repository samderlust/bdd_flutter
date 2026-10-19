import 'dart:io';

import 'test_result.dart';

/// Frames from the test framework itself, skipped when pointing at the
/// line that failed.
final RegExp _frameworkFrame = RegExp(r'^(package:(flutter_test|flutter|test_api|matcher|stack_trace)/|dart:)');

/// Turns [TestResult]s into the report printed by `dart run bdd_flutter test`.
///
/// BDD tests are grouped by feature, with Scenario Outlines and Rules as
/// sub-headings; other tests follow, grouped by file. Features and files
/// are sorted by path, so the report is the same on every run.
class BDDReportFormatter {
  /// Whether to use ANSI colors.
  final bool color;

  /// Passing tests at least this slow show their duration.
  final Duration slowThreshold;

  /// Lines of a failure message to show before cutting it short.
  final int maxErrorLines;

  const BDDReportFormatter({
    this.color = false,
    this.slowThreshold = const Duration(milliseconds: 500),
    this.maxErrorLines = 8,
  });

  /// A formatter that uses colors only when stdout is a terminal that
  /// supports them and `NO_COLOR` is not set.
  factory BDDReportFormatter.forStdout() {
    final noColor = Platform.environment['NO_COLOR']?.isNotEmpty ?? false;
    return BDDReportFormatter(color: !noColor && stdout.hasTerminal && stdout.supportsAnsiEscapes);
  }

  /// The full report for [results], which took [elapsed] to run.
  String format(List<TestResult> results, {required Duration elapsed}) {
    final buffer = StringBuffer();
    final byFile = _byFile(results);
    for (final MapEntry(key: file, value: tests) in byFile.entries.where((e) => e.value.first.isBdd)) {
      _writeFeature(buffer, file, tests);
    }
    final others = byFile.entries.where((e) => !e.value.first.isBdd).toList();
    if (others.isNotEmpty) {
      buffer.writeln('\n${_bold('Other tests')}');
      for (final MapEntry(key: file, value: tests) in others) {
        buffer.writeln('  ${_cyan(file.split(RegExp(r'[/\\]')).last)}');
        _writeTests(buffer, tests, indent: 4, groupsToSkip: 0);
      }
    }
    _writeSummary(buffer, results, elapsed);
    return buffer.toString();
  }

  Map<String, List<TestResult>> _byFile(List<TestResult> results) {
    final byFile = <String, List<TestResult>>{};
    for (final result in results) {
      byFile.putIfAbsent(result.file, () => []).add(result);
    }
    final files = byFile.keys.toList()..sort();
    return {for (final file in files) file: byFile[file]!};
  }

  void _writeFeature(StringBuffer buffer, String file, List<TestResult> tests) {
    final name = tests.first.groups.firstOrNull ?? file;
    final featurePath = file.replaceFirst(RegExp(r'\.bdd_test\.dart$'), '.feature');
    buffer.writeln('\n${_bold(name)}  ${_dim(featurePath)}');
    if (tests.every((t) => t.status == TestStatus.skipped)) {
      buffer.writeln('  ${_dim('○ ${tests.length} scenario${tests.length == 1 ? '' : 's'} skipped')}');
      return;
    }
    _writeTests(buffer, tests, indent: 2, groupsToSkip: 1);
  }

  /// Writes [tests] with a heading each time their group changes. The first
  /// [groupsToSkip] groups are already shown by the caller.
  void _writeTests(StringBuffer buffer, List<TestResult> tests, {required int indent, required int groupsToSkip}) {
    var previous = <String>[];
    for (final test in tests) {
      final groups = test.groups.skip(groupsToSkip).toList();
      final shared = _sharedLength(previous, groups);
      for (var level = shared; level < groups.length; level++) {
        buffer.writeln('${' ' * (indent + level * 2)}${groups[level]}');
      }
      _writeTest(buffer, test, indent + groups.length * 2);
      previous = groups;
    }
  }

  int _sharedLength(List<String> a, List<String> b) {
    var i = 0;
    while (i < a.length && i < b.length && a[i] == b[i]) {
      i++;
    }
    return i;
  }

  void _writeTest(StringBuffer buffer, TestResult test, int indent) {
    final pad = ' ' * indent;
    final time = _showsDuration(test) ? '  ${_dim(_duration(test.duration))}' : '';
    switch (test.status) {
      case TestStatus.passed:
        buffer.writeln('$pad${_green('✓')} ${test.name}$time');
      case TestStatus.skipped:
        buffer.writeln('$pad${_dim('○ ${test.name} (skipped)')}');
      case TestStatus.failed:
        buffer.writeln('$pad${_red('✗ ${test.name}')}$time');
        _writeFailure(buffer, test, '$pad    ');
    }
  }

  bool _showsDuration(TestResult test) {
    return test.status == TestStatus.failed || (test.status == TestStatus.passed && test.duration >= slowThreshold);
  }

  void _writeFailure(StringBuffer buffer, TestResult test, String pad) {
    final lines = (test.error ?? '').trimRight().split('\n');
    for (final line in lines.take(maxErrorLines)) {
      buffer.writeln('$pad${_red(line)}');
    }
    if (lines.length > maxErrorLines) buffer.writeln('$pad${_dim('… ${lines.length - maxErrorLines} more lines')}');
    final location = _location(test.stackTrace);
    if (location != null) buffer.writeln('$pad${_dim('at $location')}');
  }

  /// The first stack frame in the user's steps file, else the first frame
  /// outside the test framework.
  String? _location(String? stackTrace) {
    if (stackTrace == null) return null;
    final frames = stackTrace
        .split('\n')
        .map((l) => l.trim().replaceAll(RegExp(r'\s+'), ' '))
        .where((l) => l.isNotEmpty)
        .toList();
    return frames.where((f) => f.contains('_steps.dart')).firstOrNull ??
        frames.where((f) => !_frameworkFrame.hasMatch(f)).firstOrNull;
  }

  void _writeSummary(StringBuffer buffer, List<TestResult> results, Duration elapsed) {
    int count(TestStatus status) => results.where((r) => r.status == status).length;
    final failed = count(TestStatus.failed);
    final skipped = count(TestStatus.skipped);
    final parts = [
      _green('${count(TestStatus.passed)} passed'),
      failed > 0 ? _red('$failed failed') : '0 failed',
      if (skipped > 0) _dim('$skipped skipped'),
    ];
    buffer
      ..writeln('\n${_dim('─' * 50)}')
      ..writeln('${results.length} tests: ${parts.join(', ')}   ${_dim('(${_duration(elapsed)})')}');
  }

  String _duration(Duration d) {
    if (d.inMilliseconds < 1000) return '${d.inMilliseconds}ms';
    return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
  }

  String _paint(String code, String text) => color ? '\x1B[${code}m$text\x1B[0m' : text;
  String _green(String text) => _paint('32', text);
  String _red(String text) => _paint('31', text);
  String _cyan(String text) => _paint('36', text);
  String _dim(String text) => _paint('2', text);
  String _bold(String text) => _paint('1', text);
}
