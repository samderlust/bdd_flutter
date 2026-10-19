# BDD Flutter

[![pub package](https://img.shields.io/pub/v/bdd_flutter.svg)](https://pub.dev/packages/bdd_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://www.buymeacoffee.com/samderlust)

Write Flutter tests as Gherkin scenarios in plain English. BDD Flutter generates the test code from your `.feature` files; you write each step once, as a typed Dart method.

## Features

- Parses `.feature` files with the official Cucumber parser ([`cucumber_gherkin`](https://pub.dev/packages/cucumber_gherkin)), so the full Gherkin syntax and 70+ spoken languages work
- **One method per step, reused everywhere.** Quoted text and numbers become typed parameters, so `I add 2 "apple"` and `I add <qty> "<item>"` share `iAdd(num qty, String item)`
- **The analyzer tracks your steps.** A generated interface lists every step; your class implements it, so a missing or outdated step is a compile error, not a silent pass
- **Your code is never overwritten.** Generated files and your steps file are separate
- One test per Scenario Outline row, each with fresh state
- Widget tests and unit tests, `@skip`, and Gherkin tags passed to `dart test --tags`
- Generated code is run through `dart format`

## Installation

Requires Dart 3.8 or later. Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  bdd_flutter: ^2.0.0
```

## Quick Start

1. Create `test/cart/cart.feature`:

```gherkin
@unitTest
Feature: Shopping cart
  Background:
    Given an empty cart

  Scenario: Add and remove items
    When I add 2 "apple" at 1.5 each
    But I remove "apple"
    Then the cart has 0 item

  Scenario Outline: Total for several items
    When I add <quantity> "<item>" at <price> each
    Then the total for "<item>" is <total>

    Examples: Small orders
      | item  | quantity | price | total |
      | apple | 1        | 1.5   | 1.5   |
      | pear  | 2        | 2     | 4     |
```

2. Generate the files:

```bash
dart run bdd_flutter build
```

3. Implement the steps in `test/cart/cart_steps.dart`. The analyzer tells you which ones are missing.

4. Run the tests:

```bash
flutter test
```

or `dart run bdd_flutter test` for a Feature/Scenario report.

## How It Works

```
                       dart run bdd_flutter build
                                  │
  cart.feature ───────────────────┼──► cart.bdd_steps.dart   generated, rewritten every build
                                  │      ShoppingCartStepsContract: one method per step
                                  ├──► cart.bdd_test.dart    generated, rewritten every build
                                  │      the tests
                                  └──► cart_steps.dart       created once, then yours
                                         ShoppingCartSteps: your step code

  cart_steps.dart     implements  cart.bdd_steps.dart   analyzer flags missing or outdated steps
  cart.bdd_test.dart  calls       cart_steps.dart       flutter test runs it
```

`build` reads every `.feature` file, works out the distinct steps, and writes the contract and the tests. It creates your steps file only if it does not exist, then formats what it wrote with `dart format`. Run it again whenever a `.feature` file changes.

## Generated Files

For `test/cart/cart.feature`, `build` writes three files next to it:

| File | Owner | What it holds |
| --- | --- | --- |
| `cart.bdd_steps.dart` | bdd_flutter, rewritten on every build | `ShoppingCartStepsContract`: one method per distinct step |
| `cart_steps.dart` | **you**; created once, never touched again | `ShoppingCartSteps implements ShoppingCartStepsContract` |
| `cart.bdd_test.dart` | bdd_flutter, rewritten on every build | The tests |

### `cart.bdd_steps.dart`

```dart
abstract interface class ShoppingCartStepsContract {
  /// `Given an empty cart`
  Future<void> anEmptyCart();

  /// `When I add 2 "apple" at 1.5 each`
  /// `When I add <quantity> "<item>" at <price> each`
  Future<void> iAddAtEach(num quantity, String item, num price);

  /// `But I remove "apple"`
  Future<void> iRemove(String text);

  /// `Then the cart has 0 item`
  Future<void> theCartHasItem(num number);

  /// `Then the total for "<item>" is <total>`
  Future<void> theTotalForIs(String item, num total);
}
```

### `cart_steps.dart` (yours)

The first build creates it with every method throwing `UnimplementedError`. Replace the bodies; keep state in fields.

```dart
class ShoppingCartSteps implements ShoppingCartStepsContract {
  late Cart cart;

  @override
  Future<void> anEmptyCart() async => cart = Cart();

  @override
  Future<void> iAddAtEach(num quantity, String item, num price) async =>
      cart.add(item, price.toDouble(), quantity.toInt());

  @override
  Future<void> iRemove(String text) async => cart.remove(text);

  @override
  Future<void> theCartHasItem(num number) async => expect(cart.itemCount, number);

  @override
  Future<void> theTotalForIs(String item, num total) async => expect(cart.totalFor(item), total);
}
```

When you add a step to the feature and run `build`, the contract gains a method and the analyzer reports it missing in your class; the IDE's "Create missing overrides" quick fix writes the stub. When you remove or reword a step, your old method gets an `override_on_non_overriding_member` warning. `build` prints both lists too.

### `cart.bdd_test.dart`

```dart
void main() {
  group('Shopping cart', () {
    test('Add and remove items', () async {
      final steps = ShoppingCartSteps();
      // Background
      // Given an empty cart
      await steps.anEmptyCart();
      // Scenario
      // When I add 2 "apple" at 1.5 each
      await steps.iAddAtEach(2, 'apple', 1.5);
      // But I remove "apple"
      await steps.iRemove('apple');
      // Then the cart has 0 item
      await steps.theCartHasItem(0);
    });
    group('Total for several items', () {
      test('Small orders #1 (item: apple, quantity: 1, price: 1.5, total: 1.5)', () async {
        final steps = ShoppingCartSteps();
        await steps.anEmptyCart();
        await steps.iAddAtEach(1, 'apple', 1.5);
        await steps.theTotalForIs('apple', 1.5);
      });
      // ... one test per row
    });
  });
}
```

Every test creates a fresh `ShoppingCartSteps`, so tests never share state.

## Steps and Parameters

Values are taken out of the step text and passed as parameters:

| In the step | Becomes |
| --- | --- |
| `"quoted text"`, including `"<column>"` | `String` |
| A number on its own: `2`, `-1`, `1.5` | `num` |
| A bare `<column>` in a Scenario Outline | `num` if every value in the column is a number, `bool` if all are `true`/`false`, else `String` |
| A doc string (`"""`) | `String docString` |
| A data table | `List<List<String>> dataTable` (header row included) |

Steps with the same text once values are taken out share one method, whatever their keyword.

```
I add 2 "apple" at 1.5 each                 ┐
I add 1 "pear" at 2 each                    ├─► I add {num} {string} at {num} each ─► iAddAtEach(num quantity, String item, num price)
I add <quantity> "<item>" at <price> each   ┘
the cart has 1 item                         ┐
the cart has 0 item                         ┴─► the cart has {num} item            ─► theCartHasItem(num number)
``` Parameters are named after the placeholder (`<first_name>` → `firstName`), or `text`, `number`, `flag` otherwise.

To avoid losing data, a number stays part of the method name when it is part of something else: `3rd`, `09:00`, `$10.00`, `15%`, `1-second`. A number Dart would print differently (`007`, `1.50`) also stays as text, and an Examples column with such a value is passed as `String`.

Accented letters are folded for names (`j'incrémente` → `jincremente`, `Tiếng Việt` → `tiengViet`). Steps with no Latin letters get a stable name like `stepA1b2c3`; the doc comment shows the original text.

### Widget tests

In widget tests the steps class gets a `tester` field, set before the first step:

```dart
class LoginSteps implements LoginStepsContract {
  @override
  late WidgetTester tester;

  @override
  Future<void> iTapTheLoginButton() async {
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
  }
}
```

A step used by both unit and widget scenarios has one signature.

## Tags

| Tag | Scope | Effect |
| --- | --- | --- |
| `@unitTest` | Feature, Rule, Scenario | Generate `test()` |
| `@widgetTest` | Feature, Rule, Scenario | Generate `testWidgets()` |
| `@skip` | Feature, Rule, Scenario, Examples | Generate the test with `skip: true` |
| any other, e.g. `@smoke` | Feature, Rule, Scenario, Examples | Passed to the test as `tags: ['smoke']` |

The closest `@unitTest`/`@widgetTest` wins; with none, `generate_widget_tests` in the config decides. Run tagged tests with `flutter test --tags smoke`. `build` lists the tags it saw; declare them in `dart_test.yaml` to avoid warnings. Tags that are not valid `dart test` tag names are left out.

## Gherkin Support

| Syntax | How bdd_flutter uses it |
| --- | --- |
| `Given` / `When` / `Then` / `And` / `But` / `*` | One call each; the keyword does not affect the method |
| `Background:` | Runs at the start of every test in the feature |
| `Rule:` | A `group('Rule: …')`; its own `Background:` runs after the feature's |
| `Scenario Outline:` / `Examples:` | A group with one test per row, named after the Examples block and row values |
| Several `Examples:` blocks | Each keeps its name and tags; a column missing from a block keeps its `<column>` text |
| `<column>` in doc strings and tables | Filled with the row's value |
| `# comments`, descriptions, `\|` in tables | Supported |
| `# language: fr` | Keywords in any [Gherkin language](https://cucumber.io/docs/gherkin/languages/) |

Invalid Gherkin is reported with line and column; that file is skipped and `build` exits with code 1:

```
Failed: Invalid Gherkin in test/login/login.feature:
  (4:3): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, ..., got 'this line is not Gherkin'
```

## Configuration

`.bdd_flutter/config.yaml`:

```yaml
# Where to scan for .feature files
test_dir: "test/"

# For scenarios without @unitTest or @widgetTest
generate_widget_tests: true

# Feature files to skip
ignore_features:
  - test/features/login.feature

# Imports added to each new _steps.dart file
additional_imports:
  - "package:mocktail/mocktail.dart"

# Steps class suffix: CartSteps, CartStepsContract
steps_suffix: "Steps"
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `test_dir` | String | `test/` | Directory to scan for `.feature` files |
| `generate_widget_tests` | bool | `true` | Default test kind for scenarios without a decorator |
| `ignore_features` | List | `[]` | Feature file paths to skip |
| `additional_imports` | List | `[]` | Imports added to new `_steps.dart` files |
| `steps_suffix` | String | `Steps` | Suffix of the steps class name |

## Commands

| Command | Description |
| --- | --- |
| `build` | Rewrite the generated files for every feature; create missing `_steps.dart` files |
| `migrate` | Move a 1.x project to 2.0 (see below) |
| `test` | Run all tests with a Feature/Scenario report |

## Upgrading from 1.x

1.x put your step code in `.bdd_scenarios.dart`, one class per scenario, with literal values in method names. 2.0 uses one steps class per feature with typed parameters. Commit your work, then run:

```bash
dart run bdd_flutter migrate
```

For each feature with a `.bdd_scenarios.dart` file, `migrate`:

- creates `_steps.dart` with your imports, top-level declarations and fields carried over;
- copies a 1.x method body as working code when the 2.0 method takes no values and every 1.x version of it was the same;
- otherwise puts each 1.x body above the new method as a comment, followed by a `throw`, for you to adapt to the new parameters;
- generates the 2.0 contract and test file;
- renames the old file to `.bdd_scenarios.dart.bak` and removes `.bdd_flutter/manifest.yaml`, which 2.0 does not use.

`build` skips any feature that still has a `.bdd_scenarios.dart` file and no `_steps.dart` file. Search for `UnimplementedError` to find what is left, then delete the `.bak` files. If you had set `scenario_suffix`, keep it in the config until you have migrated: `migrate` uses it to find your 1.x classes.

## Test Report

`dart run bdd_flutter test` runs every test file with `flutter test` and prints BDD tests by feature, then other tests by file:

```
Shopping cart  test/cart/cart.feature
  ✗ Add and remove items  25ms
      Expected: <0>
        Actual: <1>
      at test/cart/cart_steps.dart 27:5 ShoppingCartSteps.theCartHasItem
  Total for several items
    ✓ Small orders #1 (item: apple, quantity: 1, price: 1.5, total: 1.5)
    ✓ Small orders #2 (item: pear, quantity: 2, price: 2, total: 4)
  Rule: A closed cart cannot change
    ✓ Adding to a closed cart

Note auto-sync  test/complex/complex1.feature
  ○ 10 scenarios skipped

Other tests
  string_utils_test.dart
    capitalize
      ✓ capitalizes first letter

──────────────────────────────────────────────────
65 tests: 54 passed, 1 failed, 10 skipped   (4.4s)
```

- Scenario Outline rows and Rules are nested under their scenario or rule
- A failure shows its message and the line in your `_steps.dart` that failed
- Durations are shown only for failed tests and tests slower than 500 ms
- Features and files are sorted by path, so the report is the same on every run
- Colors are used only in a terminal, and never when `NO_COLOR` is set
- The command exits with `flutter test`'s exit code, so it works in CI

## Project Structure

```
your_project/
├── .bdd_flutter/
│   └── config.yaml                 # optional
├── test/
│   └── cart/
│       ├── cart.feature
│       ├── cart_steps.dart         # yours
│       ├── cart.bdd_steps.dart   # generated
│       └── cart.bdd_test.dart      # generated
└── pubspec.yaml
```

Every generated file matches `*.bdd_*.dart` and your own files never do, so one glob is enough for `.gitignore`, coverage excludes or `analyzer: exclude`. Commit the generated files so `flutter test` works on a fresh clone without running `build`, or ignore them and run `dart run bdd_flutter build` in CI. bdd_flutter does not use `build_runner`, so its files do not end in `.g.dart`.

## Support

If bdd_flutter saves you time, you can buy me a coffee:

<a href="https://www.buymeacoffee.com/samderlust"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy me a coffee" height="50"></a>

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
