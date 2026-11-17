import 'dart:io';

import 'package:bdd_flutter/src/domain/hook_kind.dart';
import 'package:bdd_flutter/src/infrastructure/steps/steps_file_reader.dart';
import 'package:test/test.dart';

void main() {
  const reader = StepsFileReader();
  const path = 'test/cart/cart_steps.dart';

  group('StepsFileReader', () {
    test('reads step definitions with their expression, method and parameters', () {
      // Arrange
      const source = r'''
import 'package:bdd_flutter/bdd_flutter.dart';

class CartSteps {
  @StepDefinition('I have {int} cucumber(s)')
  Future<void> iHaveCucumbers(int count) async {}

  @Given('the table:')
  Future<void> theTable(List<List<String>> table) async {}
}
''';

      // Act
      final file = reader.parse(source, path: path);

      // Assert
      expect(file.problems, isEmpty);
      final steps = file.classNamed('CartSteps')!.steps;
      expect(steps.map((s) => s.expression), ['I have {int} cucumber(s)', 'the table:']);
      expect(steps.map((s) => s.methodName), ['iHaveCucumbers', 'theTable']);
      expect(steps.first.parameters.single.declaration, 'int count');
      expect(steps.last.parameters.single.dartType, 'List<List<String>>');
      expect(steps.first.location.toString(), '$path:4');
      expect(steps.first.ownerName, 'CartSteps');
    });

    test('accepts every step alias, raw, adjacent and prefixed annotations', () {
      // Arrange
      const source = r'''
import 'package:bdd_flutter/bdd_flutter.dart' as bdd;

class S {
  @bdd.Given('a')
  @bdd.When('b')
  Future<void> ab() async {}

  @Then(r'costs $1')
  Future<void> c() async {}

  @StepDefinition('long ' 'text')
  Future<void> d() async {}
}
''';

      // Act
      final steps = reader.parse(source, path: path).classNamed('S')!.steps;

      // Assert
      expect(steps.map((s) => s.expression), ['a', 'b', r'costs $1', 'long text']);
      expect(steps.map((s) => s.methodName), ['ab', 'ab', 'c', 'd']);
    });

    test('reads parameter types, named after the method unless a name is given', () {
      // Arrange
      const source = r'''
class S {
  @ParameterType(r'shipped|pending')
  static OrderStatus status(String value) => OrderStatus.values.byName(value);

  @ParameterType(r'\$\d+', name: 'money')
  static Money parseMoney(String value) => Money.parse(value);
}
''';

      // Act
      final types = reader.parse(source, path: path).classNamed('S')!.parameterTypes;

      // Assert
      expect(types.map((t) => t.name), ['status', 'money']);
      expect(types.map((t) => t.regex), ['shipped|pending', r'\$\d+']);
      expect(types.map((t) => t.methodName), ['status', 'parseMoney']);
      expect(types.map((t) => t.dartType), ['OrderStatus', 'Money']);
    });

    test('reads hooks', () {
      // Arrange
      const source = '''
class S {
  @Before()
  Future<void> open() async {}

  @After()
  void close() {}
}
''';

      // Act
      final hooks = reader.parse(source, path: path).classNamed('S')!.hooks;

      // Assert
      expect(hooks.map((h) => h.kind), [HookKind.before, HookKind.after]);
      expect(hooks.map((h) => h.methodName), ['open', 'close']);
    });

    test('reads mixins and marks them', () {
      // Arrange
      const source = '''
mixin SharedSteps {
  @StepDefinition('I am logged in')
  Future<void> iAmLoggedIn() async {}
}
''';

      // Act
      final shared = reader.parse(source, path: path).classNamed('SharedSteps')!;

      // Assert
      expect(shared.isMixin, isTrue);
      expect(shared.steps.single.methodName, 'iAmLoggedIn');
    });

    test('records parameter kinds and whether tester is declared', () {
      // Arrange
      const source = '''
class A {
  late WidgetTester tester;

  @Given('a {int}')
  Future<void> a(int n, [int? m]) async {}

  @Given('b {int}')
  Future<void> b(int n, {String? note, required int x}) async {}
}
mixin B {
  WidgetTester get tester;
}
class C {
  final int tester = 0;
}
''';

      // Act
      final file = reader.parse(source, path: path);

      // Assert
      final steps = file.classNamed('A')!.steps;
      expect(steps.first.parameters.map((p) => p.isOptional), [false, true]);
      expect(steps.last.parameters.map((p) => p.isOptional), [false, true, false]);
      expect(steps.last.parameters.map((p) => p.isNamed), [false, true, true]);
      expect(file.classNamed('A')!.declaresTester, isTrue);
      expect(file.classNamed('B')!.declaresTester, isTrue);
      expect(file.classNamed('C')!.declaresTester, isFalse);
    });

    test('records the mixins a class uses', () {
      // Arrange
      const source = '''
class CartSteps with SharedSteps, Helpers implements CartStepsContract {}
class Plain {}
''';

      // Act
      final file = reader.parse(source, path: path);

      // Assert
      expect(file.classNamed('CartSteps')!.mixins, ['SharedSteps', 'Helpers']);
      expect(file.classNamed('Plain')!.mixins, isEmpty);
    });

    test('ignores methods and annotations that are not bdd_flutter ones', () {
      // Arrange
      const source = '''
class S {
  @override
  String toString() => 'S';

  Future<void> helper() async {}
}
''';

      // Act
      final file = reader.parse(source, path: path);

      // Assert
      expect(file.problems, isEmpty);
      expect(file.classNamed('S')!.steps, isEmpty);
    });

    test('reports expressions that are not string literals', () {
      // Arrange
      const source = r'''
const text = 'x';
class S {
  @StepDefinition(text)
  Future<void> a() async {}

  @When('I have $text')
  Future<void> b() async {}

  @Then()
  Future<void> c() async {}
}
''';

      // Act
      final file = reader.parse(source, path: path);

      // Assert
      expect(file.classNamed('S')!.steps, isEmpty);
      expect(file.problems.map((p) => p.location.line), [3, 6, 9]);
      expect(file.problems.first.message, '@StepDefinition needs one string literal expression.');
    });

    test('reports invalid parameter types and hooks', () {
      // Arrange
      const source = r'''
class S {
  @ParameterType('a')
  A notStatic(String value) => A();

  @ParameterType('b')
  static B twoArgs(String value, int other) => B();

  @ParameterType('c', name: someName)
  static C named(String value) => C();

  @Before()
  Future<void> withArgument(int x) async {}
}
''';

      // Act
      final file = reader.parse(source, path: path);

      // Assert
      expect(file.classNamed('S')!.parameterTypes, isEmpty);
      expect(file.classNamed('S')!.hooks, isEmpty);
      expect(file.problems.map((p) => p.message), [
        '@ParameterType method notStatic must be static.',
        '@ParameterType method twoArgs must take a single String.',
        '@ParameterType name must be a string literal.',
        'Hook withArgument must be an instance method without arguments.',
      ]);
    });

    test('reports syntax errors but keeps what it can read', () {
      // Arrange
      const source = '''
class S {
  @StepDefinition('ok')
  Future<void> ok() async {}

  void broken( {
}
''';

      // Act
      final file = reader.parse(source, path: path);

      // Assert
      expect(file.problems, isNotEmpty);
      expect(file.problems.first.message, startsWith('Syntax error:'));
      expect(file.classNamed('S')!.steps.single.expression, 'ok');
    });

    test('reads a missing file as empty', () {
      // Act
      final file = reader.read('${Directory.systemTemp.path}/does_not_exist_steps.dart');

      // Assert
      expect(file.classes, isEmpty);
      expect(file.problems, isEmpty);
    });
  });
}
