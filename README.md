# BDD Flutter

[![pub package](https://img.shields.io/pub/v/bdd_flutter.svg)](https://pub.dev/packages/bdd_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://www.buymeacoffee.com/samderlust)

Write Flutter tests as Gherkin scenarios in plain English. BDD Flutter generates the test code from your `.feature` files; you write each step once, as a typed Dart method marked with a [Cucumber Expression](https://github.com/cucumber/cucumber-expressions#readme).

> **3.0 is a breaking change.** Steps are now matched with Cucumber Expressions instead of a generated contract. To keep the 2.x behaviour, set `steps_mode: contract` in `.bdd_flutter/config.yaml`; to move to expressions, run `dart run bdd_flutter migrate`. See [Upgrading from 2.x](#upgrading-from-2x).

## Features

- Parses `.feature` files with the official Cucumber parser ([`cucumber_gherkin`](https://pub.dev/packages/cucumber_gherkin)), so the full Gherkin syntax and 70+ spoken languages work
- **Standard Cucumber Expressions** through the official [`cucumber_expressions`](https://pub.dev/packages/cucumber_expressions) package: `{int}`, `{float}`, `{string}`, `{word}`, optional text `item(s)` and alternatives `belly/stomach`
- **Your own types**: `@ParameterType` turns `shipped` into an `OrderStatus`, `$10.00` into a `Money`
- **Checked at build time.** `build` matches every step and generates tests that call your methods directly, so a wrong signature is a compile error and an undefined or ambiguous step fails its test with a clear message
- **Your code is never overwritten.** Generated tests and your steps file are separate
- **Steps shared across features are written once**, in a mixin every feature can use
- `@Before` / `@After` hooks, one test per Scenario Outline row with fresh state
- Widget tests and unit tests, `@skip`, and Gherkin tags passed to `dart test --tags`
- Generated code is run through `dart format`

## Installation

Requires Dart 3.8 or later. Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  bdd_flutter: ^3.0.0
```

Feedback and bug reports are welcome in the [issues](https://github.com/samderlust/bdd_flutter/issues).

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
    Then the cart has 0 items

  Scenario Outline: Total for several items
    When I add <quantity> "<item>" at <price> each
    Then the total for "<item>" is <total>

    Examples: Small orders
      | item  | quantity | price | total |
      | apple | 1        | 1.5   | 1.5   |
      | pear  | 2        | 2     | 4     |
```

2. Generate the tests:

```bash
dart run bdd_flutter build
```

`build` creates `test/cart/cart_steps.dart` with an empty `ShoppingCartSteps` class, and lists the steps that have no method yet.

3. Write the steps in `test/cart/cart_steps.dart`:

```dart
import 'package:bdd_flutter/bdd_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

class ShoppingCartSteps {
  late Cart cart;

  @Given('an empty cart')
  Future<void> anEmptyCart() async => cart = Cart();

  @When('I add {int} {string} at {float} each')
  Future<void> iAdd(int quantity, String item, double price) async => cart.add(item, price, quantity);

  @When('I remove {string}')
  Future<void> iRemove(String item) async => cart.remove(item);

  @Then('the cart has {int} item(s)')
  Future<void> theCartHas(int count) async => expect(cart.itemCount, count);

  @Then('the total for {string} is {float}')
  Future<void> theTotalFor(String item, double total) async => expect(cart.totalFor(item), total);
}
```

4. Run `build` again, then the tests:

```bash
dart run bdd_flutter build
flutter test
```

or `dart run bdd_flutter test` for a Feature/Scenario report.

## How It Works

```
                       dart run bdd_flutter build
                                  │
  cart.feature ──────────┐        │
                         ├────────┼──► cart.bdd_test.dart    generated, rewritten every build
  cart_steps.dart ───────┘        │      calls the matching methods with typed values
    @Given/@When/@Then methods    │
  shared_steps.dart ──────────────┘    (steps used by several features)
```

`build` reads every `.feature` file and the step annotations in your steps files (from source, without running them), matches each step's text against the expressions, and writes the tests. It creates a steps file only when a feature has none, and never changes one that exists. Run it again whenever a `.feature` or steps file changes.

## Generated Files

For `test/cart/cart.feature`:

| File | Owner | What it holds |
| --- | --- | --- |
| `cart_steps.dart` | **you**; created empty once | `ShoppingCartSteps`: methods annotated with `@Given`, `@When`, `@Then` or `@StepDefinition` |
| `cart.bdd_test.dart` | bdd_flutter, rewritten on every build | The tests |

```dart
// cart.bdd_test.dart
void main() {
  group('Shopping cart', () {
    test('Add and remove items', () async {
      final steps = ShoppingCartSteps();
      // Background
      // Given an empty cart
      await steps.anEmptyCart();
      // Scenario
      // When I add 2 "apple" at 1.5 each
      await steps.iAdd(2, 'apple', 1.5);
      // But I remove "apple"
      await steps.iRemove('apple');
      // Then the cart has 0 items
      await steps.theCartHas(0);
    });
    group('Total for several items', () {
      test('Small orders #1 (item: apple, quantity: 1, price: 1.5, total: 1.5)', () async {
        final steps = ShoppingCartSteps();
        await steps.anEmptyCart();
        await steps.iAdd(1, 'apple', 1.5);
        await steps.theTotalFor('apple', 1.5);
      });
      // ... one test per row
    });
  });
}
```

Every test creates a fresh `ShoppingCartSteps`, so tests never share state.

## Step Expressions

Each step method carries a [Cucumber Expression](https://github.com/cucumber/cucumber-expressions#readme) in `@Given`, `@When`, `@Then` or the keyword-free `@StepDefinition`. The keyword is ignored when matching, as in Cucumber: `@Given('the cart is closed')` also matches `And the cart is closed` or `When the cart is closed`. A method can have several annotations.

> **mocktail users:** mocktail exports a class named `When`. Import it with `import 'package:mocktail/mocktail.dart' hide When;` (its `when(...)` function still works). `migrate` and new steps files do this for you. If another library clashes too, import bdd_flutter with a prefix instead: `import 'package:bdd_flutter/bdd_flutter.dart' as bdd;` and `@bdd.When('...')`.

| In the expression | Matches | Parameter |
| --- | --- | --- |
| `{int}` | `2`, `-1` | `int` |
| `{float}` | `1.5`, `2` | `double` |
| `{num}` | `2`, `1.5` | `num` (added by bdd_flutter; what 2.x used) |
| `{bool}` | `true`, `false` | `bool` (added by bdd_flutter) |
| `{string}` | `"apple"` or `'apple'` | `String`, without the quotes |
| `{word}` | `apple` (no spaces) | `String` |
| `{}` | anything | `String` |
| `item(s)` | `item` or `items` | optional text |
| `belly/stomach` | `belly` or `stomach` | alternatives |
| `\(`, `\{`, `\/` | a literal `(`, `{`, `/` (write the expression as a raw string, `r'...'`) | |

A doc string is passed as an extra `String`, and a data table as an extra `List<List<String>>` (header row included), after the expression's parameters:

```dart
@Given('the prices:')
Future<void> thePrices(List<List<String>> table) async { ... }
```

In a Scenario Outline, each Examples row's values are put into the step text before matching, so `I add <quantity> "<item>" at <price> each` matches `I add {int} {string} at {float} each` for every row.

Expressions and regexes must be string literals: `build` reads them from source.

### Custom parameter types

Put `@ParameterType` on a static method that takes the matched text. The type is named after the method, unless you pass `name:`:

```dart
enum OrderStatus { shipped, pending, cancelled }

class OrderSteps {
  @ParameterType(r'shipped|pending|cancelled')
  static OrderStatus status(String value) => OrderStatus.values.byName(value);

  @Given('the order is {status}')
  Future<void> theOrderIs(OrderStatus status) async { ... }
}
```

The generated test converts the value with your method: `await steps.theOrderIs(OrderSteps.status('shipped'));`. A type declared in the shared steps mixin can be used by every feature.

### Undefined and ambiguous steps

| Situation | What happens |
| --- | --- |
| No expression matches | `build` lists it; the test fails with `Undefined step: ...` |
| Several expressions match | The test fails with `Ambiguous step: ...`, listing the methods |
| Invalid expression or unknown `{type}` | `build` reports it with the file and line |

The test file always compiles, so one missing step never stops the other tests from running.

### Steps shared across features

A step used by several features, like `Given I am logged in as {string}`, is written once in **`mixin SharedSteps`** in `shared_steps.dart` at the root of your test directory. Feature steps classes mix it in:

```dart
// test/shared_steps.dart (yours)
mixin SharedSteps {
  String? user;

  @Given('I am logged in as {string}')
  Future<void> iAmLoggedInAs(String name) async => user = name;
}

// test/cart/cart_steps.dart
class ShoppingCartSteps with SharedSteps {
  @When('I add {int} {string} at {float} each')
  Future<void> iAdd(int quantity, String item, double price) async { ... }
}
```

- A feature's own class is matched first, so it can override a shared step.
- Shared steps run on the same steps object, so the mixin's fields hold state for one test, like the class's.
- A step matched only by the mixin, in a class without `with SharedSteps`, fails its test with a message saying what to add.
- To use the tester in shared steps, declare `WidgetTester get tester;` in the mixin.

### Hooks

```dart
class ShoppingCartSteps with SharedSteps {
  @Before()
  Future<void> openDatabase() async { ... }

  @After()
  Future<void> closeDatabase() async { ... }
}
```

`@Before` methods run before the Background; `@After` methods run after the scenario, even when a step fails (they are registered with `addTearDown`). Hooks in `SharedSteps` run before the class's own `@Before` hooks and after its `@After` hooks.

### Widget tests

In widget tests the steps class gets a `tester` field, set before the first step:

```dart
class LoginSteps {
  late WidgetTester tester;

  @When('I tap the login button')
  Future<void> iTapTheLoginButton() async {
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
  }
}
```

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
| `Given` / `When` / `Then` / `And` / `But` / `*` | One call each; the keyword does not affect matching |
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

# Steps class suffix: CartSteps
steps_suffix: "Steps"

# How steps are connected to code:
#   expressions (default): @Given/@When/@Then methods matched with Cucumber Expressions
#   contract: 2.x behaviour, a generated contract the steps class implements
steps_mode: expressions
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `test_dir` | String | `test/` | Directory to scan for `.feature` files |
| `generate_widget_tests` | bool | `true` | Default test kind for scenarios without a decorator |
| `ignore_features` | List | `[]` | Feature file paths to skip |
| `additional_imports` | List | `[]` | Imports added to new `_steps.dart` files |
| `steps_suffix` | String | `Steps` | Suffix of the steps class name |
| `steps_mode` | `expressions` or `contract` | `expressions` | `contract` keeps the 2.x generated contract; any other value is an error |

## Commands

| Command | Description |
| --- | --- |
| `build` | Rewrite the generated tests for every feature, create missing steps files, and list undefined steps and other problems |
| `migrate` | Move a 2.x project (or a 1.x one) to expressions (see below) |
| `test` | Run all tests with a Feature/Scenario report |

## Upgrading from 2.x

3.0 changes how steps are connected to code. `.feature` files do not change. Pick one:

**Keep the 2.x behaviour.** Add one line to `.bdd_flutter/config.yaml` (create it if needed):

```yaml
steps_mode: contract
```

`build` then works exactly as in 2.x; see [Contract mode](#contract-mode-2x). Without this line, a 2.x project does not build until it is migrated.

**Move to expressions.** Commit your work, then run:

```bash
dart run bdd_flutter migrate
```

For each feature, and for `shared_steps.dart`, `migrate`:

- adds `@Given`, `@When` or `@Then` (after the keyword of the method's first step) to every method, with an expression built from the 2.x step text: `@When('I add {num} {string} at {num} each')`;
- removes `implements <Feature>StepsContract` and `@override`, and deletes the `.bdd_steps.dart` contracts;
- hides mocktail's `When` in your imports;
- keeps signatures and method bodies as they are (`{num}` and `{bool}` exist so `num` and `bool` parameters still match), so the generated tests stay the same.

Afterwards you can tighten expressions at your own pace: `{num}` to `{int}` or `{float}`, `item` to `item(s)`, values to custom types.

## Contract mode (2.x)

With `steps_mode: contract`, `build` writes three files per feature, as in 2.x:

| File | Owner | What it holds |
| --- | --- | --- |
| `cart.bdd_steps.dart` | bdd_flutter, rewritten on every build | `ShoppingCartStepsContract`: one method per distinct step |
| `cart_steps.dart` | **you**; created once, never touched again | `ShoppingCartSteps implements ShoppingCartStepsContract` |
| `cart.bdd_test.dart` | bdd_flutter, rewritten on every build | The tests |

```dart
// cart.bdd_steps.dart
abstract interface class ShoppingCartStepsContract {
  /// `When I add 2 "apple" at 1.5 each`
  /// `When I add <quantity> "<item>" at <price> each`
  Future<void> iAddAtEach(num quantity, String item, num price);
}

// cart_steps.dart
class ShoppingCartSteps implements ShoppingCartStepsContract {
  @override
  Future<void> iAddAtEach(num quantity, String item, num price) async =>
      cart.add(item, price.toDouble(), quantity.toInt());
}
```

Values are taken out of the step text and passed as parameters; steps with the same text once values are taken out share one method, whatever their keyword:

| In the step | Becomes |
| --- | --- |
| `"quoted text"`, including `"<column>"` | `String` |
| A number on its own: `2`, `-1`, `1.5` | `num` |
| A bare `<column>` in a Scenario Outline | `num` if every value in the column is a number, `bool` if all are `true`/`false`, else `String` |
| A doc string (`"""`) | `String docString` |
| A data table | `List<List<String>> dataTable` (header row included) |

A number stays part of the method name when it is part of something else (`3rd`, `09:00`, `$10.00`, `15%`, `1-second`) or when Dart would print it differently (`007`, `1.50`). Accented letters are folded for names (`Tiếng Việt` → `tiengViet`); steps with no Latin letters get a stable name like `stepA1b2c3`.

When you add a step, the contract gains a method and the analyzer reports it missing in your class; when you remove or reword one, your old method gets an `override_on_non_overriding_member` warning. `build` prints both lists too.

Shared steps live in `mixin SharedSteps` (`shared_steps.dart`), created with stubs the first time a step is used by two features; a step is shared when the mixin implements it with the same name and parameter types. `build` prints a tip when a step becomes shared later, and warns about mixin steps no feature uses.

## Upgrading from 1.x

1.x put your step code in `.bdd_scenarios.dart`, one class per scenario, with literal values in method names. Commit your work, then run `migrate`: it moves 1.x code to 2.x steps classes, then on to expressions (or stops at 2.x with `steps_mode: contract`):

```bash
dart run bdd_flutter migrate
```

For each feature with a `.bdd_scenarios.dart` file, `migrate`:

- creates `_steps.dart` with your imports, top-level declarations and fields carried over;
- copies a 1.x method body as working code when the new method takes no values and every 1.x version of it was the same;
- otherwise puts each 1.x body above the new method as a comment, followed by a `throw`, for you to adapt to the new parameters;
- generates the test file (and, in contract mode, the contract);
- renames the old file to `.bdd_scenarios.dart.bak` and removes `.bdd_flutter/manifest.yaml`, which 2.0 and later do not use.

`build` skips any feature that still has a `.bdd_scenarios.dart` file and no `_steps.dart` file. Search for `UnimplementedError` to find what is left, then delete the `.bak` files. If you had set `scenario_suffix`, keep it in the config until you have migrated: `migrate` uses it to find your 1.x classes.

## Test Report

`dart run bdd_flutter test` runs every test file with `flutter test` and prints BDD tests by feature, then other tests by file:

```
Shopping cart  test/cart/cart.feature
  ✗ Add and remove items  25ms
      Expected: <0>
        Actual: <1>
      at test/cart/cart_steps.dart 27:5 ShoppingCartSteps.theCartHas
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
│   ├── shared_steps.dart           # yours: steps used by several features
│   └── cart/
│       ├── cart.feature
│       ├── cart_steps.dart         # yours: @Given/@When/@Then methods
│       └── cart.bdd_test.dart      # generated
│                                   # (+ cart.bdd_steps.dart in contract mode)
└── pubspec.yaml
```

Every generated file matches `*.bdd_*.dart` and your own files never do, so one glob is enough for `.gitignore`, coverage excludes or `analyzer: exclude`. Commit the generated files so `flutter test` works on a fresh clone without running `build`, or ignore them and run `dart run bdd_flutter build` in CI. bdd_flutter does not use `build_runner`, so its files do not end in `.g.dart`.

## Support

If bdd_flutter saves you time, you can buy me a coffee:

<a href="https://www.buymeacoffee.com/samderlust"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy me a coffee" height="50"></a>

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
