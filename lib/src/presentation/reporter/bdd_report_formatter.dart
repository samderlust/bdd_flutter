import 'dart:io';

const String _red = '\x1B[31m';
const String _green = '\x1B[32m';
const String _cyan = '\x1B[36m';
const String _dim = '\x1B[2m';
const String _reset = '\x1B[0m';

/// Formats BDD test results into a colored Feature/Scenario report.
///
/// Used by [BDDTestRunner] to display results from `flutter test --machine`.
class BDDReportFormatter {
  final List<FeatureReport> features = [];
  final List<TestFileReport> testFiles = [];
  DateTime? _startTime;

  void start() {
    _startTime = DateTime.now();
  }

  FeatureReport getOrCreateFeature(String name) {
    for (final feature in features) {
      if (feature.name == name) return feature;
    }
    final feature = FeatureReport(name: name);
    features.add(feature);
    return feature;
  }

  TestFileReport _getOrCreateTestFile(String fileName) {
    for (final file in testFiles) {
      if (file.fileName == fileName) return file;
    }
    final file = TestFileReport(fileName: fileName);
    testFiles.add(file);
    return file;
  }

  void addTestResult({
    required String featureName,
    required String scenarioName,
    required bool passed,
    String? error,
    Duration? duration,
  }) {
    final feature = getOrCreateFeature(featureName);
    feature.scenarios.add(ScenarioResult(
      name: scenarioName,
      passed: passed,
      error: error,
      duration: duration,
    ));
  }

  void addRegularTestResult({
    required String fileName,
    required String groupName,
    required String testName,
    required bool passed,
    String? error,
    Duration? duration,
  }) {
    final file = _getOrCreateTestFile(fileName);
    final group = file.getOrCreateGroup(groupName);
    group.results.add(ScenarioResult(
      name: testName,
      passed: passed,
      error: error,
      duration: duration,
    ));
  }

  String formatReport() {
    final buffer = StringBuffer();
    final totalDuration = _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;

    int totalTests = 0;
    int totalPassed = 0;
    int totalFailed = 0;

    // BDD Test Report
    if (features.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${_cyan}BDD Test Report$_reset');
      buffer.writeln('$_dim${'=' * 50}$_reset');

      for (final feature in features) {
        buffer.writeln();
        buffer.writeln('  ${_cyan}Feature: ${feature.name}$_reset');

        for (final scenario in feature.scenarios) {
          totalTests++;
          final durationStr = scenario.duration != null ? ' $_dim(${scenario.duration!.inMilliseconds}ms)$_reset' : '';

          if (scenario.passed) {
            totalPassed++;
            buffer.writeln('    $_green✓$_reset ${scenario.name}$durationStr');
          } else {
            totalFailed++;
            buffer.writeln('    $_red✗ ${scenario.name}$_reset$durationStr');
            if (scenario.error != null) {
              buffer.writeln('      $_red${scenario.error}$_reset');
            }
          }
        }
      }
    }

    // Regular Test Report
    if (testFiles.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${_cyan}Non-BDD Test Report$_reset');
      buffer.writeln('$_dim${'=' * 50}$_reset');

      for (final file in testFiles) {
        buffer.writeln();
        buffer.writeln('  ${_cyan}Test File: ${file.fileName}$_reset');

        for (final group in file.groups) {
          if (group.name.isNotEmpty) {
            buffer.writeln('    ${_dim}${group.name}$_reset');
          }
          final indent = group.name.isNotEmpty ? '      ' : '    ';

          for (final result in group.results) {
            totalTests++;
            final durationStr = result.duration != null ? ' $_dim(${result.duration!.inMilliseconds}ms)$_reset' : '';

            if (result.passed) {
              totalPassed++;
              buffer.writeln('$indent$_green✓$_reset ${result.name}$durationStr');
            } else {
              totalFailed++;
              buffer.writeln('$indent$_red✗ ${result.name}$_reset$durationStr');
              if (result.error != null) {
                buffer.writeln('$indent  $_red${result.error}$_reset');
              }
            }
          }
        }
      }
    }

    // Summary
    buffer.writeln();
    buffer.writeln('$_dim${'─' * 50}$_reset');

    final passedStr = totalPassed > 0 ? '$_green$totalPassed passed$_reset' : '0 passed';
    final failedStr = totalFailed > 0 ? '$_red$totalFailed failed$_reset' : '0 failed';
    buffer.writeln('  $totalTests tests: $passedStr, $failedStr');
    buffer.writeln('  Time: ${totalDuration.inMilliseconds}ms');
    buffer.writeln();

    return buffer.toString();
  }

  void printReport() {
    stdout.write(formatReport());
  }
}

/// Aggregated test results for a single feature.
class FeatureReport {
  final String name;
  final List<ScenarioResult> scenarios = [];

  FeatureReport({required this.name});
}

/// Aggregated test results for a single regular test file.
class TestFileReport {
  final String fileName;
  final List<TestGroupReport> groups = [];

  TestFileReport({required this.fileName});

  TestGroupReport getOrCreateGroup(String name) {
    for (final group in groups) {
      if (group.name == name) return group;
    }
    final group = TestGroupReport(name: name);
    groups.add(group);
    return group;
  }
}

/// Aggregated test results for a group within a test file.
class TestGroupReport {
  final String name;
  final List<ScenarioResult> results = [];

  TestGroupReport({required this.name});
}

/// The result of a single scenario test execution.
class ScenarioResult {
  final String name;
  final bool passed;
  final String? error;
  final Duration? duration;

  ScenarioResult({
    required this.name,
    required this.passed,
    this.error,
    this.duration,
  });
}
