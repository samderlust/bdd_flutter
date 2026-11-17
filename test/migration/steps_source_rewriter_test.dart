import 'package:bdd_flutter/src/infrastructure/migration/steps_source_rewriter.dart';
import 'package:test/test.dart';

void main() {
  const rewriter = StepsSourceRewriter();

  group('StepsSourceRewriter', () {
    test('annotates step methods and drops the contract', () {
      // Arrange
      const source = '''
import 'package:example/src/cart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cart.bdd_steps.dart';

/// The steps.
class ShoppingCartSteps implements ShoppingCartStepsContract {
  late Cart cart;

  @override
  late WidgetTester tester;

  /// Adds things.
  @override
  Future<void> iAddAtEach(num quantity, String item, num price) async {
    cart.add(item, price.toDouble(), quantity.toInt());
  }

  @override
  String toString() => 'steps';
}
''';

      // Act
      final result = rewriter.rewrite(
        source,
        ownerName: 'ShoppingCartSteps',
        annotations: {
          'iAddAtEach': ["@When('I add {num} {string} at {num} each')"],
        },
        contractClass: 'ShoppingCartStepsContract',
        contractFileName: 'cart.bdd_steps.dart',
      );

      // Assert
      expect(result.annotated, ['iAddAtEach']);
      expect(result.source, '''
import 'package:bdd_flutter/bdd_flutter.dart';
import 'package:example/src/cart.dart';
import 'package:flutter_test/flutter_test.dart';


/// The steps.
class ShoppingCartSteps {
  late Cart cart;

  late WidgetTester tester;

  /// Adds things.
  @When('I add {num} {string} at {num} each')
  Future<void> iAddAtEach(num quantity, String item, num price) async {
    cart.add(item, price.toDouble(), quantity.toInt());
  }

  @override
  String toString() => 'steps';
}
''');
    });

    test('keeps other interfaces, the mixin and the tester override when asked', () {
      // Arrange
      const source = '''
class CartSteps with SharedSteps implements CartStepsContract, Other {
  @override
  late WidgetTester tester;

  @override
  Future<void> a() async {}
}
''';

      // Act
      final result = rewriter.rewrite(
        source,
        ownerName: 'CartSteps',
        annotations: {
          'a': ["@Given('a')", "@Given('b')"],
        },
        contractClass: 'CartStepsContract',
        keepTesterOverride: true,
      );

      // Assert
      expect(result.source, contains('class CartSteps with SharedSteps implements Other {'));
      expect(result.source, contains('  @override\n  late WidgetTester tester;'));
      expect(result.source, contains("  @Given('a')\n  @Given('b')\n  Future<void> a() async {}"));
      expect(result.source, startsWith("import 'package:bdd_flutter/bdd_flutter.dart';\n\n"));
    });

    test('annotates a mixin and leaves annotated methods alone', () {
      // Arrange
      const source = '''
import 'package:bdd_flutter/bdd_flutter.dart';

mixin SharedSteps {
  Future<void> a() async {}

  @Given('b')
  Future<void> b() async {}
}
''';

      // Act
      final result = rewriter.rewrite(
        source,
        ownerName: 'SharedSteps',
        annotations: {
          'a': ["@Then('a')"],
          'b': ["@Then('other')"],
        },
      );

      // Assert
      expect(result.annotated, ['a']);
      expect(result.source, contains("  @Then('a')\n  Future<void> a() async {}"));
      expect(result.source, contains("  @Given('b')\n  Future<void> b() async {}"));
      expect("import 'package:bdd_flutter/bdd_flutter.dart';".allMatches(result.source), hasLength(1));
    });

    test("hides mocktail's When, which clashes with @When", () {
      // Arrange
      const source = '''
import 'package:mocktail/mocktail.dart';

class S implements SContract {
  @override
  Future<void> a() async {}
}
''';

      // Act
      final result = rewriter.rewrite(
        source,
        ownerName: 'S',
        annotations: {
          'a': ["@When('a')"],
        },
        contractClass: 'SContract',
      );

      // Assert
      expect(result.source, contains("import 'package:mocktail/mocktail.dart' hide When;"));
    });

    test('adds When to an existing hide, and leaves show lists without it alone', () {
      // Arrange
      const hiding =
          "import 'package:mocktail/mocktail.dart' hide Mock;\n\nclass S {\n  Future<void> a() async {}\n}\n";
      const showing =
          "import 'package:mocktail/mocktail.dart' show Mock;\n\nclass S {\n  Future<void> a() async {}\n}\n";
      const annotations = {
        'a': ["@When('a')"],
      };

      // Act
      final hidden = rewriter.rewrite(hiding, ownerName: 'S', annotations: annotations);
      final shown = rewriter.rewrite(showing, ownerName: 'S', annotations: annotations);

      // Assert
      expect(hidden.source, contains("import 'package:mocktail/mocktail.dart' hide Mock, When;"));
      expect(shown.source, contains("import 'package:mocktail/mocktail.dart' show Mock;"));
    });

    test('reports a missing class and changes nothing', () {
      // Arrange
      const source = "import 'cart.bdd_steps.dart';\n\nclass Renamed implements CartStepsContract {}\n";

      // Act
      final result = rewriter.rewrite(
        source,
        ownerName: 'CartSteps',
        annotations: const {},
        contractClass: 'CartStepsContract',
        contractFileName: 'cart.bdd_steps.dart',
      );

      // Assert
      expect(result.ownerFound, isFalse);
      expect(result.source, source);
    });

    test('is a no-op on a migrated file', () {
      // Arrange
      const source =
          "import 'package:bdd_flutter/bdd_flutter.dart';\n\nclass S {\n  @When('a')\n  Future<void> a() async {}\n}\n";

      // Act
      final result = rewriter.rewrite(
        source,
        ownerName: 'S',
        annotations: {
          'a': ["@When('a')"],
        },
        contractClass: 'SContract',
        contractFileName: 's.bdd_steps.dart',
      );

      // Assert
      expect(result.source, source);
      expect(result.annotated, isEmpty);
    });
  });
}
