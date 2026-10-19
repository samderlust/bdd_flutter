import 'package:bdd_flutter/src/infrastructure/migration/dart_source_mask.dart';
import 'package:bdd_flutter/src/infrastructure/migration/legacy_names.dart';
import 'package:bdd_flutter/src/infrastructure/migration/legacy_scenarios_file.dart';
import 'package:test/test.dart';

void main() {
  group('maskDartSource', () {
    test('blanks comments and strings but keeps positions and code', () {
      const source = "a('}'); // }\nb(\"{\"); /* { */ c(r'\\');";

      final masked = maskDartSource(source);

      expect(masked.length, source.length);
      expect(masked.contains('{'), isFalse);
      expect(masked.contains('}'), isFalse);
      expect(masked, contains('a('));
      expect(masked, contains('\n'));
    });

    test('handles interpolation with quotes and braces inside', () {
      const source = r"x = '${m['k']} }'; y();";

      final masked = maskDartSource(source);

      expect(masked, endsWith('; y();'));
      expect(masked.contains('}'), isFalse);
    });

    test('handles triple-quoted strings', () {
      const source = "x = '''\n}\n'''; y();";

      expect(maskDartSource(source), endsWith('; y();'));
      expect(maskDartSource(source).contains('}'), isFalse);
    });
  });

  group('LegacyScenariosFile.parse', () {
    const source = '''
library steps;
import 'package:a/a.dart';
import "package:b/b.dart";

final helper = {'a': 1};

class CounterBackground {
  Future<void> iHaveACounter(WidgetTester tester) async {
    counter = 0; // reset }
  }
}

class IncrementScenario {
  late int value;
  IncrementScenario();
  int get doubled => value * 2;
  Future<void> iIncrement(WidgetTester tester, String by) async {
    // TODO: Implement When I increment
  }
  Future<void> arrow() async => print('x');
}
''';

    test('splits imports, top-level code and classes', () {
      final file = LegacyScenariosFile.parse(source);

      expect(file.imports, ["import 'package:a/a.dart';", 'import "package:b/b.dart";']);
      expect(file.topLevel, ["final helper = {'a': 1};"]);
      expect(file.classes.keys, ['CounterBackground', 'IncrementScenario']);
    });

    test('reads step methods with parameters and bodies', () {
      final method = LegacyScenariosFile.parse(source).classes['CounterBackground']!.methods['iHaveACounter']!;

      expect(method.parameters, 'WidgetTester tester');
      expect(method.body.trim(), 'counter = 0; // reset }');
      expect(method.hasCode, isTrue);
    });

    test('marks TODO-only bodies as having no code', () {
      final method = LegacyScenariosFile.parse(source).classes['IncrementScenario']!.methods['iIncrement']!;

      expect(method.hasCode, isFalse);
    });

    test('keeps fields and getters, drops constructors and unreadable step methods', () {
      final members = LegacyScenariosFile.parse(source).classes['IncrementScenario']!.otherMembers;

      expect(members, ['late int value;', 'int get doubled => value * 2;']);
    });
  });

  group('LegacyNames', () {
    test('reproduces 1.x class names', () {
      expect(LegacyNames.className('Incrémenter'), 'IncrMenter');
      expect(LegacyNames.className('2 refunds'), 'X2Refunds');
    });

    test('reproduces 1.x method names', () {
      expect(LegacyNames.methodName('I add 2 "apple" at 1.5 each'), 'iAdd2AppleAt15Each');
      expect(LegacyNames.methodName('the counter is <expected_value>'), 'theCounterIsExpectedValue');
      expect(LegacyNames.methodName('2 refunds today'), 'refundsToday');
    });
  });
}
