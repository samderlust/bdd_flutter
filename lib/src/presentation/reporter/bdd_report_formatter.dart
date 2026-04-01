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

  String formatReport() {
    final buffer = StringBuffer();
    final totalDuration = _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;

    buffer.writeln();
    buffer.writeln('${_cyan}BDD Test Report$_reset');
    buffer.writeln('$_dim${'=' * 50}$_reset');

    int totalScenarios = 0;
    int totalPassed = 0;
    int totalFailed = 0;

    for (final feature in features) {
      buffer.writeln();
      buffer.writeln('  ${_cyan}Feature: ${feature.name}$_reset');

      for (final scenario in feature.scenarios) {
        totalScenarios++;
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

    buffer.writeln();
    buffer.writeln('$_dim${'─' * 50}$_reset');

    final passedStr = totalPassed > 0 ? '$_green$totalPassed passed$_reset' : '0 passed';
    final failedStr = totalFailed > 0 ? '$_red$totalFailed failed$_reset' : '0 failed';
    buffer.writeln('  $totalScenarios scenarios: $passedStr, $failedStr');
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
