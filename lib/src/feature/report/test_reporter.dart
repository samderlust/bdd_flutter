import 'dart:io';

const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String reset = '\x1B[0m';

/// A class that handles test reporting for BDD tests
class BDDTestReporter {
  /// The name of the feature being tested
  final String featureName;

  /// Whether to export the test results to a file
  final bool exportToFile;

  /// Whether to rethrow the error after reporting it
  /// in production code, this should be true
  /// so that it wont effect the test run on CICD
  final bool shouldRethrow;

  final List<ScenarioReport> _scenarios = [];

  final Function(String)? logCallback;

  FeatureTestOverview? _overview;
  DateTime? _startTime;

  StringBuffer? _reportBuffer;

  BDDTestReporter({
    required this.featureName,
    this.exportToFile = false,
    this.shouldRethrow = false,
    this.logCallback,
  });

  void startScenario(String name) {
    _scenarios.add(ScenarioReport(name: name.noSpace, steps: {}));
  }

  void reportStep(String name, bool status, String? error) {
    _scenarios.last.addStep(
      StepReport(name: name, status: status, error: error),
    );
  }

  void _log(String message) {
    if (logCallback != null) {
      logCallback!(message);
    } else {
      print(message);
    }
  }

  void printReport() {
    _log(_reportBuffer?.toString() ?? '');
  }

  void testStarted() {
    _startTime = DateTime.now();
  }

  void testFinished() {
    final totalTime = DateTime.now().difference(_startTime!);
    _overview = FeatureTestOverview(
      featureName: featureName,
      totalScenarios: _scenarios.length,
      totalSteps:
          _scenarios.fold(0, (sum, scenario) => sum + scenario.steps.length),
      totalPassed: _scenarios.fold(
          0,
          (sum, scenario) =>
              sum + scenario.steps.values.where((step) => step.status).length),
      totalFailed: _scenarios.fold(
          0,
          (sum, scenario) =>
              sum + scenario.steps.values.where((step) => !step.status).length),
      totalTime: totalTime,
    );
    _generateReport();
  }

  Future<void> guard(Future<void> Function() step, String name) async {
    try {
      await step();
      reportStep(name, true, null);
    } catch (e) {
      reportStep(name, false, e.toString());
      if (shouldRethrow) {
        rethrow;
      }
    }
  }

  void _generateReport() {
    _reportBuffer = StringBuffer();

    _reportBuffer!.writeln(_overview?.toOverviewString() ?? '');
    _reportBuffer!.writeln('--------------------------------');
    for (var scenario in _scenarios) {
      _reportBuffer!.writeln('\tScenario: ${scenario.name}');
      for (var step in scenario.steps.values) {
        _reportBuffer!.writeln(
            '\t\t${step.status ? green : red}${step.name}: ${step.status ? '✓' : '✗'}${reset}');
      }
    }
    final errorSteps = _scenarios
        .expand((scenario) => scenario.steps.values
            .where((step) => step.error != null)
            .map((step) => step))
        .toList();
    if (errorSteps.isNotEmpty) {
      _reportBuffer!.writeln('--------------------------------');
      _reportBuffer!.writeln('ERROR:');
      //get all errors
      for (var step in errorSteps) {
        _reportBuffer!.writeln('\t\t${step.name}: ${step.error}');
      }
    }
  }

  void saveReportToFile([String dir = '/']) {
    if (_reportBuffer == null || _reportBuffer!.isEmpty) {
      return;
    }

    final fileName =
        '${featureName}_report_${DateTime.now().toIso8601String()}.txt';
    final filePath = '$dir/$fileName';
    final file = File(filePath);
    file.writeAsStringSync(_reportBuffer?.toString() ?? '');
    _log('Report saved to $filePath');
  }
}

class ScenarioReport {
  final NoSpaceString name;
  final Map<String, StepReport> steps;

  ScenarioReport({required this.name, required this.steps});

  void addStep(StepReport step) {
    steps[step.name] = step;
  }
}

class StepReport {
  final NoSpaceString name;
  final bool status;
  final String? error;

  StepReport({required this.name, required this.status, this.error});
}

typedef NoSpaceString = String;

extension NoSpaceStringX on String {
  NoSpaceString get noSpace => replaceAll(' ', '_');
}

class FeatureTestOverview {
  final String featureName;
  final int totalScenarios;
  final int totalSteps;
  final int totalPassed;
  final int totalFailed;
  final Duration totalTime;
  FeatureTestOverview({
    required this.featureName,
    required this.totalScenarios,
    required this.totalSteps,
    required this.totalPassed,
    required this.totalFailed,
    required this.totalTime,
  });

  String toOverviewString() {
    return 'Feature: $featureName\n'
        'Total Scenarios: $totalScenarios\n'
        'Total Steps: $totalSteps\n'
        'Total Passed: $totalPassed\n'
        'Total Failed: $totalFailed\n'
        'Total Time: ${totalTime.inMilliseconds}ms\n';
  }
}
