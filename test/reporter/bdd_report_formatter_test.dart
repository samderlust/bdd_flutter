import 'package:bdd_flutter/src/presentation/reporter/bdd_report_formatter.dart';
import 'package:bdd_flutter/src/presentation/reporter/test_result.dart';
import 'package:test/test.dart';

TestResult _result(
  String file,
  List<String> groups,
  String name, {
  TestStatus status = TestStatus.passed,
  int ms = 5,
  String? error,
  String? stackTrace,
}) {
  return TestResult(
    file: file,
    groups: groups,
    name: name,
    status: status,
    duration: Duration(milliseconds: ms),
    error: error,
    stackTrace: stackTrace,
  );
}

void main() {
  const formatter = BDDReportFormatter();
  const cart = 'test/cart/cart.bdd_test.dart';

  String format(List<TestResult> results) => formatter.format(results, elapsed: const Duration(milliseconds: 4966));

  group('BDDReportFormatter', () {
    test('nests Scenario Outline rows and Rules under the feature', () {
      final report = format([
        _result(cart, ['Shopping cart'], 'Add and remove items'),
        _result(cart, ['Shopping cart', 'Total'], 'Small orders #1 (item: apple)'),
        _result(cart, ['Shopping cart', 'Total'], 'Small orders #2 (item: pear)'),
        _result(cart, ['Shopping cart', 'Rule: Closed carts'], 'Adding to a closed cart'),
      ]);

      expect(
        report,
        contains(
          'Shopping cart  test/cart/cart.feature\n'
          '  ✓ Add and remove items\n'
          '  Total\n'
          '    ✓ Small orders #1 (item: apple)\n'
          '    ✓ Small orders #2 (item: pear)\n'
          '  Rule: Closed carts\n'
          '    ✓ Adding to a closed cart\n',
        ),
      );
    });

    test('sorts features by path', () {
      final report = format([
        _result('test/z/z.bdd_test.dart', ['Zebra'], 'a'),
        _result('test/a/a.bdd_test.dart', ['Apple'], 'a'),
      ]);

      expect(report.indexOf('Apple'), lessThan(report.indexOf('Zebra')));
    });

    test('collapses a fully skipped feature to one line', () {
      final report = format([
        for (var i = 0; i < 10; i++)
          _result('test/c/c.bdd_test.dart', ['Note auto-sync'], 'S$i', status: TestStatus.skipped),
      ]);

      expect(report, contains('Note auto-sync  test/c/c.feature\n  ○ 10 scenarios skipped\n'));
      expect(report, isNot(contains('S0')));
    });

    test('marks single skipped tests', () {
      final report = format([
        _result(cart, ['Shopping cart'], 'Add'),
        _result(cart, ['Shopping cart'], 'Clear', status: TestStatus.skipped),
      ]);

      expect(report, contains('  ○ Clear (skipped)\n'));
    });

    test('shows durations only for slow and failed tests', () {
      final report = format([
        _result(cart, ['Shopping cart'], 'Fast', ms: 120),
        _result(cart, ['Shopping cart'], 'Slow', ms: 1234),
      ]);

      expect(report, contains('  ✓ Fast\n'));
      expect(report, contains('  ✓ Slow  1.2s\n'));
    });

    test('shows the failure message and the line in the steps file', () {
      final report = format([
        _result(
          'test/login/login.bdd_test.dart',
          ['Login'],
          'Failed login',
          status: TestStatus.failed,
          ms: 83,
          error: 'Expected: one widget\n  Actual: none',
          stackTrace:
              'package:flutter_test/src/matchers.dart 10:3  expect\n'
              'test/login/login_steps.dart 71:5  LoginSteps.iShouldSee\n'
              'test/login/login.bdd_test.dart 40:7  main',
        ),
      ]);

      expect(
        report,
        contains(
          '  ✗ Failed login  83ms\n'
          '      Expected: one widget\n'
          '        Actual: none\n'
          '      at test/login/login_steps.dart 71:5 LoginSteps.iShouldSee\n',
        ),
      );
    });

    test('cuts long failure messages short', () {
      final report = const BDDReportFormatter(maxErrorLines: 2).format([
        _result(cart, ['Shopping cart'], 'Add', status: TestStatus.failed, error: 'a\nb\nc\nd'),
      ], elapsed: Duration.zero);

      expect(report, contains('      a\n      b\n      … 2 more lines\n'));
    });

    test('lists other tests by file name and group', () {
      final report = format([
        _result('test/unit/string_utils_test.dart', ['capitalize'], 'capitalizes first letter'),
        _result('test/unit/string_utils_test.dart', [], 'top level'),
      ]);

      expect(
        report,
        contains(
          'Other tests\n'
          '  string_utils_test.dart\n'
          '    capitalize\n'
          '      ✓ capitalizes first letter\n'
          '    ✓ top level\n',
        ),
      );
    });

    test('counts passed, failed and skipped in the summary', () {
      final report = format([
        _result(cart, ['Shopping cart'], 'A'),
        _result(cart, ['Shopping cart'], 'B', status: TestStatus.failed),
        _result(cart, ['Shopping cart'], 'C', status: TestStatus.skipped),
      ]);

      expect(report, endsWith('3 tests: 1 passed, 1 failed, 1 skipped   (5.0s)\n'));
    });

    test('uses no color codes unless asked', () {
      final plain = format([
        _result(cart, ['Shopping cart'], 'A'),
      ]);
      final colored = const BDDReportFormatter(color: true).format([
        _result(cart, ['Shopping cart'], 'A'),
      ], elapsed: Duration.zero);

      expect(plain, isNot(contains('\x1B[')));
      expect(colored, contains('\x1B[32m✓\x1B[0m'));
    });
  });
}
