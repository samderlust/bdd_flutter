import 'dart:convert';

import 'package:bdd_flutter/src/presentation/reporter/test_event_collector.dart';
import 'package:bdd_flutter/src/presentation/reporter/test_result.dart';
import 'package:test/test.dart';

/// Events shaped like `flutter test --machine` output for one BDD file with
/// a feature group, a Rule group, a passing, a failing, a skipped and a
/// hidden loading test.
List<Map<String, dynamic>> _events() {
  Map<String, dynamic> start(int id, String name, List<int> groups, {bool skip = false}) => {
    'type': 'testStart',
    'time': 100,
    'test': {
      'id': id,
      'name': name,
      'suiteID': 0,
      'groupIDs': groups,
      'metadata': {'skip': skip},
    },
  };
  Map<String, dynamic> done(int id, String result, {bool skipped = false, bool hidden = false}) => {
    'type': 'testDone',
    'time': 350,
    'testID': id,
    'result': result,
    'skipped': skipped,
    'hidden': hidden,
  };
  return [
    {
      'type': 'suite',
      'suite': {'id': 0, 'path': '/project/test/cart/cart.bdd_test.dart'},
    },
    start(1, 'loading /project/test/cart/cart.bdd_test.dart', []),
    done(1, 'success', hidden: true),
    {
      'type': 'group',
      'group': {'id': 2, 'name': ''},
    },
    {
      'type': 'group',
      'group': {'id': 3, 'name': 'Shopping cart'},
    },
    {
      'type': 'group',
      'group': {'id': 4, 'name': 'Shopping cart Rule: Closed carts'},
    },
    start(5, 'Shopping cart Add items', [2, 3]),
    done(5, 'success'),
    start(6, 'Shopping cart Rule: Closed carts Add to a closed cart', [2, 3, 4]),
    {
      'type': 'error',
      'testID': 6,
      'error': 'Expected: 0\n  Actual: 1',
      'stackTrace': 'test/cart/cart_steps.dart 12:5  x',
    },
    {'type': 'error', 'testID': 6, 'error': 'second error', 'stackTrace': ''},
    done(6, 'failure'),
    start(7, 'Shopping cart Clear', [2, 3], skip: true),
    done(7, 'success', skipped: true),
  ];
}

void main() {
  late List<TestResult> results;

  setUp(() {
    final collector = TestEventCollector(rootPath: '/project');
    for (final event in _events()) {
      collector.addLine(jsonEncode(event));
    }
    collector.addLine('not json');
    results = collector.results;
  });

  group('TestEventCollector', () {
    test('leaves out hidden loading tests', () {
      expect(results.map((r) => r.name), ['Add items', 'Add to a closed cart', 'Clear']);
    });

    test('keeps each group with its own name, outermost first', () {
      expect(results[0].groups, ['Shopping cart']);
      expect(results[1].groups, ['Shopping cart', 'Rule: Closed carts']);
    });

    test('makes the file path relative to the root', () {
      expect(results.first.file, 'test/cart/cart.bdd_test.dart');
      expect(results.first.isBdd, isTrue);
    });

    test('reports skipped tests with their name instead of as passed', () {
      expect(results[2].status, TestStatus.skipped);
      expect(results[2].file, 'test/cart/cart.bdd_test.dart');
    });

    test('keeps the first error and its stack trace for a failed test', () {
      expect(results[1].status, TestStatus.failed);
      expect(results[1].error, 'Expected: 0\n  Actual: 1');
      expect(results[1].stackTrace, 'test/cart/cart_steps.dart 12:5  x');
    });

    test('measures duration from the runner timestamps', () {
      expect(results[0].status, TestStatus.passed);
      expect(results[0].duration, const Duration(milliseconds: 250));
    });
  });
}
