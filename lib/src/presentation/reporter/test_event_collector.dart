import 'dart:convert';

import 'test_result.dart';

/// Builds [TestResult]s from the JSON events of `flutter test --machine`.
///
/// See https://github.com/dart-lang/test/blob/master/pkgs/test/doc/json_reporter.md.
/// Skipped tests are kept: they arrive with `metadata.skip` at start and
/// `skipped: true` at the end. Hidden tests (the runner's own "loading"
/// tests) are left out.
class TestEventCollector {
  /// Strips the working directory from suite paths; empty keeps them as-is.
  final String rootPath;

  final Map<int, String> _suitePaths = {};
  final Map<int, String> _groupNames = {};
  final Map<int, Map<String, dynamic>> _tests = {};
  final Map<int, (String, String?)> _errors = {};
  final List<TestResult> _results = [];

  TestEventCollector({this.rootPath = ''});

  /// The finished tests, in the order they finished.
  List<TestResult> get results => List.unmodifiable(_results);

  /// Reads one line of output; lines that are not JSON events are ignored.
  void addLine(String line) {
    final event = _decode(line);
    if (event == null) return;
    switch (event['type']) {
      case 'suite':
        _onSuite(event['suite'] as Map<String, dynamic>);
      case 'group':
        _onGroup(event['group'] as Map<String, dynamic>);
      case 'testStart':
        final test = event['test'] as Map<String, dynamic>;
        _tests[test['id'] as int] = {...test, 'startTime': event['time']};
      case 'error':
        _errors.putIfAbsent(event['testID'] as int, () => (event['error'] as String, event['stackTrace'] as String?));
      case 'testDone':
        _onTestDone(event);
    }
  }

  Map<String, dynamic>? _decode(String line) {
    if (!line.startsWith('{')) return null;
    try {
      final decoded = jsonDecode(line);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  void _onSuite(Map<String, dynamic> suite) {
    final path = suite['path'] as String?;
    if (path != null) _suitePaths[suite['id'] as int] = _relative(path);
  }

  void _onGroup(Map<String, dynamic> group) {
    final name = group['name'] as String? ?? '';
    if (name.isNotEmpty) _groupNames[group['id'] as int] = name;
  }

  void _onTestDone(Map<String, dynamic> event) {
    final id = event['testID'] as int;
    final test = _tests.remove(id);
    if (test == null || event['hidden'] == true) return;
    final error = _errors.remove(id);
    final fullGroupNames = [
      for (final groupId in (test['groupIDs'] as List).cast<int>())
        if (_groupNames[groupId] != null) _groupNames[groupId]!,
    ];
    _results.add(
      TestResult(
        file: _suitePaths[test['suiteID']] ?? '',
        groups: _localNames(fullGroupNames),
        name: _withoutPrefix(test['name'] as String, fullGroupNames.lastOrNull),
        status: _status(event),
        error: error?.$1,
        stackTrace: error?.$2,
        duration: Duration(milliseconds: (event['time'] as int) - (test['startTime'] as int? ?? 0)),
      ),
    );
  }

  TestStatus _status(Map<String, dynamic> event) {
    if (event['skipped'] == true) return TestStatus.skipped;
    return event['result'] == 'success' ? TestStatus.passed : TestStatus.failed;
  }

  /// Group names arrive in full (`Cart Rule: Closed`); keep each one's own
  /// part (`Rule: Closed`).
  List<String> _localNames(List<String> fullNames) {
    return [for (var i = 0; i < fullNames.length; i++) _withoutPrefix(fullNames[i], i == 0 ? null : fullNames[i - 1])];
  }

  String _withoutPrefix(String fullName, String? parent) {
    if (parent == null || !fullName.startsWith('$parent ')) return fullName;
    return fullName.substring(parent.length + 1);
  }

  String _relative(String path) {
    if (rootPath.isEmpty || !path.startsWith(rootPath)) return path;
    return path.substring(rootPath.length).replaceFirst(RegExp(r'^[/\\]'), '');
  }
}
