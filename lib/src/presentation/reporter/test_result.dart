/// How a test ended.
enum TestStatus { passed, failed, skipped }

/// One finished test from `flutter test --machine`.
class TestResult {
  /// The test file, relative to the working directory when possible.
  final String file;

  /// The test's groups from outermost to innermost, each with only its own
  /// name, e.g. `['Shopping cart', 'Rule: Closed carts']`.
  final List<String> groups;

  /// The test's own name, without its groups' names.
  final String name;

  final TestStatus status;

  /// The first error reported for a failed test.
  final String? error;

  /// The stack trace of [error].
  final String? stackTrace;

  /// Time from the test's start to its end, as reported by the runner.
  final Duration duration;

  const TestResult({
    required this.file,
    required this.groups,
    required this.name,
    required this.status,
    this.error,
    this.stackTrace,
    this.duration = Duration.zero,
  });

  /// Whether [file] was generated from a `.feature` file.
  bool get isBdd => file.endsWith('.bdd_test.dart');
}
