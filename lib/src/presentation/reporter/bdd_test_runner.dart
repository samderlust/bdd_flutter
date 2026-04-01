import 'dart:convert';
import 'dart:io';

import 'bdd_report_formatter.dart';

/// Runs BDD tests via `flutter test --machine` and formats the output.
///
/// Finds all `.bdd_test.dart` files, runs them through Flutter's test runner,
/// parses the JSON event stream, and prints a BDD-formatted report grouped
/// by Feature with pass/fail per Scenario.
class BDDTestRunner {
  final BDDReportFormatter _formatter;
  final String testDir;

  BDDTestRunner({
    BDDReportFormatter? formatter,
    this.testDir = 'test/',
  }) : _formatter = formatter ?? BDDReportFormatter();

  /// Runs all test files and prints the BDD report.
  ///
  /// Discovers both `.bdd_test.dart` and regular `_test.dart` files.
  /// BDD tests are shown with the Feature/Scenario report format.
  /// Regular tests are listed with pass/fail status.
  /// Returns the exit code from `flutter test` (0 = all passed).
  Future<int> run() async {
    _formatter.start();

    final allFiles = Directory(testDir)
        .listSync(recursive: true)
        .where((f) => f.path.endsWith('_test.dart'))
        .map((f) => f.path)
        .toList();

    if (allFiles.isEmpty) {
      stdout.writeln('No test files found in "$testDir".');
      return 0;
    }

    final bddFiles = allFiles.where((f) => f.endsWith('.bdd_test.dart')).toList();
    final regularFiles = allFiles.where((f) => !f.endsWith('.bdd_test.dart')).toList();

    final parts = <String>[];
    if (bddFiles.isNotEmpty) parts.add('${bddFiles.length} BDD');
    if (regularFiles.isNotEmpty) parts.add('${regularFiles.length} regular');
    stdout.writeln('Running ${parts.join(' + ')} test file(s)...');
    stdout.writeln();

    // Run flutter test --machine with all test files
    final process = await Process.start(
      'flutter',
      ['test', '--machine', ...allFiles],
      mode: ProcessStartMode.normal,
    );

    // Track test state
    final testNames = <int, String>{};
    final testStartTimes = <int, DateTime>{};
    final testGroups = <int, String>{};
    final groupNames = <int, String>{};
    final errorMessages = <int, String>{};
    final testSuiteFiles = <int, String>{};
    final suiteFiles = <int, String>{};

    // Parse JSON events line by line
    await process.stdout.transform(utf8.decoder).transform(const LineSplitter()).forEach((line) {
      _processJsonLine(
        line,
        testNames: testNames,
        testStartTimes: testStartTimes,
        testGroups: testGroups,
        groupNames: groupNames,
        errorMessages: errorMessages,
        testSuiteFiles: testSuiteFiles,
        suiteFiles: suiteFiles,
      );
    });

    // Capture stderr for unexpected errors
    final stderr = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;

    if (stderr.isNotEmpty && exitCode != 0 && _formatter.features.isEmpty) {
      stdout.writeln(stderr);
    }

    _formatter.printReport();

    return exitCode;
  }

  void _processJsonLine(
    String line, {
    required Map<int, String> testNames,
    required Map<int, DateTime> testStartTimes,
    required Map<int, String> testGroups,
    required Map<int, String> groupNames,
    required Map<int, String> errorMessages,
    required Map<int, String> testSuiteFiles,
    required Map<int, String> suiteFiles,
  }) {
    if (line.trim().isEmpty) return;

    dynamic json;
    try {
      json = jsonDecode(line);
    } catch (_) {
      return;
    }

    if (json is! Map) return;

    final type = json['type'] as String?;

    switch (type) {
      case 'suite':
        final suite = json['suite'] as Map?;
        if (suite != null) {
          final suiteId = suite['id'] as int?;
          final suitePath = suite['path'] as String?;
          if (suiteId != null && suitePath != null) {
            suiteFiles[suiteId] = suitePath;
          }
        }
        break;

      case 'group':
        final group = json['group'] as Map?;
        if (group != null) {
          final groupId = group['id'] as int?;
          final groupName = group['name'] as String?;
          if (groupId != null && groupName != null && groupName.isNotEmpty) {
            groupNames[groupId] = groupName;
          }
        }
        break;

      case 'testStart':
        final test = json['test'] as Map?;
        if (test != null) {
          final testId = test['id'] as int?;
          final testName = test['name'] as String?;
          final suiteId = test['suiteID'] as int?;
          final groupIds = (test['groupIDs'] as List?)?.cast<int>() ?? [];

          if (testId != null && testName != null) {
            // Skip loading tests (they have metadata)
            final metadata = test['metadata'] as Map?;
            if (metadata != null && (metadata['skip'] == true)) break;

            testNames[testId] = testName;
            testStartTimes[testId] = DateTime.now();

            // Track which suite file this test belongs to
            if (suiteId != null && suiteFiles.containsKey(suiteId)) {
              testSuiteFiles[testId] = suiteFiles[suiteId]!;
            }

            // Find the parent group (feature name)
            if (groupIds.length >= 2) {
              final featureGroupId = groupIds[1]; // first real group after root
              testGroups[testId] = groupNames[featureGroupId] ?? '';
            }
          }
        }
        break;

      case 'error':
        final testId = json['testID'] as int?;
        final error = json['error'] as String?;
        if (testId != null && error != null) {
          errorMessages[testId] = error;
        }
        break;

      case 'testDone':
        final testId = json['testID'] as int?;
        final result = json['result'] as String?;
        final hidden = json['hidden'] as bool? ?? false;

        if (testId != null && result != null && !hidden) {
          final fullName = testNames[testId] ?? '';
          final featureName = testGroups[testId] ?? '';
          final startTime = testStartTimes[testId];
          final duration = startTime != null ? DateTime.now().difference(startTime) : null;
          final suiteFile = testSuiteFiles[testId] ?? '';
          final isBddTest = suiteFile.endsWith('.bdd_test.dart');

          if (isBddTest) {
            // BDD test: show as Feature/Scenario
            String scenarioName = fullName;
            if (featureName.isNotEmpty && fullName.startsWith(featureName)) {
              scenarioName = fullName.substring(featureName.length).trim();
            }

            if (scenarioName.isNotEmpty && featureName.isNotEmpty) {
              _formatter.addTestResult(
                featureName: featureName,
                scenarioName: scenarioName,
                passed: result == 'success',
                error: errorMessages[testId],
                duration: duration,
              );
            }
          } else {
            // Regular test: group by file name, extract group and test name
            final fileName = suiteFile.split('/').last;
            final groupName = featureName;
            String testName = fullName;
            if (groupName.isNotEmpty && fullName.startsWith(groupName)) {
              testName = fullName.substring(groupName.length).trim();
            }
            _formatter.addRegularTestResult(
              fileName: fileName,
              groupName: groupName,
              testName: testName,
              passed: result == 'success',
              error: errorMessages[testId],
              duration: duration,
            );
          }
        }
        break;
    }
  }
}
