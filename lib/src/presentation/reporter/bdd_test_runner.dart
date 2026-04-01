import 'dart:convert';
import 'dart:io';

import 'bdd_report_formatter.dart';

class BDDTestRunner {
  final BDDReportFormatter _formatter;
  final String testDir;

  BDDTestRunner({
    BDDReportFormatter? formatter,
    this.testDir = 'test/',
  }) : _formatter = formatter ?? BDDReportFormatter();

  Future<int> run() async {
    _formatter.start();

    // Find all .bdd_test.dart files
    final testFiles = Directory(testDir)
        .listSync(recursive: true)
        .where((f) => f.path.endsWith('.bdd_test.dart'))
        .map((f) => f.path)
        .toList();

    if (testFiles.isEmpty) {
      stdout.writeln('No .bdd_test.dart files found in "$testDir".');
      return 0;
    }

    stdout.writeln('Running ${testFiles.length} BDD test file(s)...');
    stdout.writeln();

    // Run flutter test --machine with all test files
    final process = await Process.start(
      'flutter',
      ['test', '--machine', ...testFiles],
      mode: ProcessStartMode.normal,
    );

    // Track test state
    final testNames = <int, String>{};
    final testStartTimes = <int, DateTime>{};
    final testGroups = <int, String>{};
    final groupNames = <int, String>{};
    final errorMessages = <int, String>{};

    // Parse JSON events line by line
    await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
      _processJsonLine(
        line,
        testNames: testNames,
        testStartTimes: testStartTimes,
        testGroups: testGroups,
        groupNames: groupNames,
        errorMessages: errorMessages,
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
          final groupIds = (test['groupIDs'] as List?)?.cast<int>() ?? [];

          if (testId != null && testName != null) {
            // Skip loading tests (they have metadata)
            final metadata = test['metadata'] as Map?;
            if (metadata != null && (metadata['skip'] == true)) break;

            testNames[testId] = testName;
            testStartTimes[testId] = DateTime.now();

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
          final duration = startTime != null
              ? DateTime.now().difference(startTime)
              : null;

          // Extract scenario name by removing the feature group prefix
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
        }
        break;
    }
  }
}
