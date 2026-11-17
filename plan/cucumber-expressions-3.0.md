# bdd_flutter 3.0: Cucumber Expressions

Status: proposal · Discussion: [#11](https://github.com/samderlust/bdd_flutter/issues/11) · Follows [#6](https://github.com/samderlust/bdd_flutter/issues/6)

## Summary

3.0 replaces the generated steps contract with Cucumber Expressions written in
the user's steps file. `build` matches every feature step against those
expressions with the official
[`cucumber_expressions`](https://pub.dev/packages/cucumber_expressions)
package, generates tests that call the matched methods, and prints a snippet
for every step nothing matches. Steps can live in the feature's own steps class
or in shared steps classes used by many features. This is a breaking change;
`migrate` moves 2.x (and 1.x) projects over without changing method bodies.

`.feature` files do not change.

The model follows Cucumber-JVM and Reqnroll (see
[Comparison with other BDD tools](#comparison-with-other-bdd-tools)), with one
deliberate difference: matching happens at build time and generated tests call
methods directly, so mistakes are compile errors.

## Why

- **Domain types.** `the order is {status}` → `OrderStatus`, `I pay {money}` →
  `Money`, converted once instead of inside every step method.
- **Different phrasings, one method.** `I have {int} cucumber(s) in my
  belly/stomach` covers wording and plural variants.
- **Standard Cucumber** where users actually see it: the expressions they write.
- **Upstream implementation.** Expression parsing, matching and escaping come
  from the official package (no dependencies, Dart `^3.3.0`).
- **Less local code.** `StepPatternParser`, `StepsCatalog`,
  `StepsContractBuilder` and the contract file go away.

### Why not keep 2.x key generation and swap in the generator

`CucumberExpressionGenerator` makes choices 2.x deliberately avoids (`{int}` vs
`{float}`, parameterizing `09:00`, `$10.00`, `007`). Wrapping it so output stays
identical needs more code than the ~80-line parser it replaces. In 3.0 the
generator only writes a **first draft** that the user owns and edits once, so
those choices stop being a problem.

### Why no compatibility flag

A `step_expressions: false` switch would keep two engines (two code paths, two
test suites, two sets of docs). `migrate` is mechanical and lossless, so 3.0
ships one engine. 2.x gets bug fixes on a `release/2.x` branch.

## Files

| File | 2.x | 3.0 |
|---|---|---|
| `cart.feature` | Gherkin | unchanged |
| `cart.bdd_steps.dart` | generated contract | **removed** |
| `cart_steps.dart` | user-owned, `implements CartStepsContract` | user-owned, methods annotated with `@Step` (or `@Given`/`@When`/`@Then`) |
| `cart.bdd_test.dart` | generated | generated, same shape |
| shared steps (e.g. `test/steps/auth_steps.dart`) | not possible | optional, listed in `config.yaml` |

## Example

```gherkin
Feature: Cart
  Scenario: Pay
    Given the order is shipped
    And I have 2 cucumbers in my belly
    When I pay $10.00
```

### First `build`: snippets for undefined steps

`build` prints them; `build --write-snippets` appends them to `cart_steps.dart`
(creating it if missing).

```dart
class CartSteps {
  @Step('the order is shipped')
  Future<void> theOrderIsShipped() async => throw UnimplementedError();

  @Step('I have {int} cucumbers in my belly')
  Future<void> iHaveCucumbersInMyBelly(int int1) async =>
      throw UnimplementedError();

  @Step(r'I pay ${float}')
  Future<void> iPay(double float1) async => throw UnimplementedError();
}
```

### After the user edits them

```dart
class CartSteps {
  @ParameterType(r'shipped|pending|cancelled') // type name = method name: {status}
  static OrderStatus status(String value) => OrderStatus.values.byName(value);

  @ParameterType(r'\$\d+\.\d{2}')
  static Money money(String value) => Money.parse(value);

  @Given('the order is {status}')
  Future<void> theOrderIs(OrderStatus status) async { ... }

  @Step('I have {int} cucumber(s) in my belly/stomach')
  Future<void> iHaveCucumbers(int count) async { ... }

  @When('I pay {money}')
  Future<void> iPay(Money amount) async { ... }
}
```

`@Given`, `@When` and `@Then` are aliases of `@Step`: matching ignores the
keyword, as in Cucumber, so `And I pay $10.00` and `Then I pay $10.00` both
match `@When('I pay {money}')`.

### Generated `cart.bdd_test.dart`

```dart
test('Pay', () async {
  final steps = CartSteps();
  await steps.theOrderIs(CartSteps.status('shipped'));
  await steps.iHaveCucumbers(2);
  await steps.iPay(CartSteps.money(r'$10.00'));
});
```

Matching happens during `build`, so a missing or mistyped method is still a
compile error in the generated test.

## Shared steps

Cucumber users expect to write `I am logged in` once and use it in every
feature. 3.0 supports that with shared steps classes listed in config:

```yaml
# .bdd_flutter/config.yaml
shared_steps:
  - test/steps/auth_steps.dart
  - test/steps/common_steps.dart
```

```dart
// test/steps/auth_steps.dart
class AuthSteps {
  @Given('I am logged in as {string}')
  Future<void> iAmLoggedInAs(String user) async { ... }
}
```

`build` matches each step against the feature's own class first, then the
shared classes. The generated test creates only the classes it uses:

```dart
test('Pay', () async {
  final steps = CartSteps();
  final authSteps = AuthSteps();
  await authSteps.iAmLoggedInAs('ann');
  await steps.iPay(CartSteps.money(r'$10.00'));
});
```

- The feature's own class wins over shared classes, so a feature can override a
  shared step. Two shared classes matching the same step is an error.
- Widget tests set `tester` on every class created (`..tester = tester`).
- Sharing state between classes (Cucumber uses DI for this) is an open question;
  the first version gives each class its own state.

## Hooks

2.x has no hooks; `Background` steps are inlined into each test. 3.0 adds
scenario hooks as annotated instance methods, on the feature class or a shared
class:

```dart
class CartSteps {
  @Before()
  Future<void> openDatabase() async { ... }

  @After()
  Future<void> closeDatabase() async { ... }
}
```

```dart
test('Pay', () async {
  final steps = CartSteps();
  await steps.openDatabase();
  addTearDown(steps.closeDatabase); // runs even when a step fails
  // Background steps, then scenario steps
});
```

Order: `@Before` hooks of shared classes, then of the feature class; `@After`
in reverse. Tag-filtered hooks (`@Before(tags: '@db')`) and per-feature hooks
(`setUpAll`) can follow later.

## Pipeline

```
BDDCLI.run(args)
  → BDDController.generateFeatureTestCases()
    → ConfigParser.loadConfig()                 # unchanged
    → FeatureParser.parseFeature()              # unchanged
      → GherkinMapper.toFeature()               # unchanged
    → StepsFileReader.read(_steps.dart,         # NEW: analyzer → @Step/@Given/@When/@Then,
                           shared_steps)        #      @ParameterType, @Before/@After
    → StepMatcher.match(step)                   # NEW: ExpressionFactory
        feature class, then shared classes
        1 match  → call with converted arguments
        2+       → build error: ambiguous step
        0        → snippet + warning
    → TestFileBuilder.build(...)                # creates used classes, hooks, calls
    → SnippetWriter.print / append              # NEW: CucumberExpressionGenerator
                                                #      append only with --write-snippets
    → checkStepsFile(...)                       # reworked diagnostics
    → DartFormatCommand.formatFiles(...)        # unchanged
```

Removed: `StepPatternParser`, `columnTypes`, `StepsCatalog`,
`StepsContractBuilder`, `StepsStubBuilder` (replaced by `SnippetWriter`).

## Decisions

| # | Topic | Decision |
|---|---|---|
| 1 | Annotation | `@Step('...')`, with `@Given`/`@When`/`@Then` as aliases. Matching ignores the keyword, as in Cucumber. |
| 2 | Custom types | `@ParameterType(regex)` on a static method taking `String`, as in Cucumber-JVM; the type name defaults to the method name (`name:` overrides it). The generated test calls `Steps.name('raw')`. |
| 3 | Built-in types | Cucumber's `{int}`, `{float}`, `{word}`, `{string}`, `{}`, plus `{num}` registered by bdd_flutter so migrated signatures stay `num`. |
| 4 | Snippets | Printed by `build`, as in Cucumber. `build --write-snippets` appends them to `_steps.dart` (file created if missing) with `UnimplementedError` bodies. Existing code is never edited. |
| 5 | Scenario Outline | Each Examples row's expanded text is matched, as in Cucumber. |
| 6 | No match | Snippet + build warning. |
| 7 | Several matches | Build error listing the expressions. |
| 8 | Reading the steps file | `analyzer`; only string-literal expressions and regexes. |
| 9 | Public API | `package:bdd_flutter/bdd_flutter.dart` exports `Step`, `Given`, `When`, `Then`, `ParameterType`, `Before` and `After`, with no CLI code. |
| 10 | Migration | `migrate` goes from 1.x or 2.x straight to 3.0. |
| 11 | 2.x | `release/2.x` branch, bug fixes only. |
| 12 | Shared steps | `shared_steps` in config; feature class matched first, then shared classes; the test creates only the classes it uses. |
| 13 | Hooks | `@Before` / `@After` instance methods; `@After` registered with `addTearDown`. |

## Argument values in generated tests

| Type | Step text | Generated argument |
|---|---|---|
| `{int}` | `2` | `2` |
| `{float}` | `1.5` | `1.5` (`1` → `1.0`) |
| `{num}` | `2` | `2` |
| `{string}` | `"apple"` / `'apple'` | `'apple'` (escaped) |
| `{word}`, `{}` | `apple` | `'apple'` |
| custom | `shipped` | `CartSteps.status('shipped')` |
| DocString / DataTable | | appended after the expression's parameters, as in 2.x |

## Migration (`dart run bdd_flutter migrate`)

A 2.x pattern key is already close to an expression:

```
2.x key:      I add {num} {string} at {num} each
3.0 @Step:    I add {num} {string} at {num} each
```

For each feature:

1. Add `@Step('<key as expression>')` to every method in `_steps.dart`.
2. Escape metacharacters in literal text: `(`, `)`, `{`, `}`, `/`, `\`.
3. Bare string `<column>` slots (unquoted in the step) become `{word}`, or
   `{}` when a value contains spaces.
4. Remove `implements XStepsContract` and `@override`.
5. Delete `.bdd_steps.dart`.
6. Strip `+docString` / `+dataTable` from the key; the trailing argument stays.

Signatures and method bodies are unchanged. 1.x projects go through the
existing 1.x → 2.x mapping first, in the same run.

## Diagnostics

- Step with no matching expression → warning + snippet.
- Step matching several expressions (in one class, or in two shared classes) → error.
- Shared steps file listed in config but missing → error.
- Expression no step uses → warning.
- Parameter count or type that disagrees with the expression → error.
- Unknown parameter type (`{colour}`) or invalid expression → error with position.

## Work order

1. Public annotations (`Step`, `Given`, `When`, `Then`, `ParameterType`, `Before`, `After`) and exports.
2. `StepsFileReader` (analyzer), for the feature's steps file and `shared_steps`.
3. `StepMatcher` over `ExpressionFactory` with a type registry (built-ins + `{num}` + custom), feature class first, then shared classes.
4. `TestFileBuilder`: create the used classes, call hooks, turn matched values into Dart literals or `Steps.type('raw')`.
5. `SnippetWriter` over `CucumberExpressionGenerator` (print; append with `--write-snippets`).
6. Remove the 2.x pattern pipeline; rework `checkStepsFile`.
7. `migrate` to 3.0.
8. Migrate `example/`; add `{status}`, `{money}`, a shared steps class and hooks.
9. README, CHANGELOG, migration guide, CLAUDE.md.

1–3 are the core; 4–7 depend on them; 8–9 last.

## Comparison with other BDD tools

| Concept | Cucumber (JVM/JS/Ruby) | Reqnroll / SpecFlow (.NET) | Behave / pytest-bdd | bdd_flutter 3.0 |
|---|---|---|---|---|
| Step definition | annotation or function + expression | attribute + expression | decorator + parse/regex | annotation + expression |
| Expression syntax | Cucumber Expressions | Cucumber Expressions or regex | `parse` format | Cucumber Expressions |
| Keyword | ignored when matching | keyword-specific by default (`[StepDefinition]` matches any) | keyword-specific | ignored (`@Step` and aliases) |
| Custom types | `@ParameterType` / `defineParameterType` | `[StepArgumentTransformation]` | `register_type` | `@ParameterType` |
| Undefined step | snippet printed | snippet suggested by the IDE | error | snippet printed (`--write-snippets` to append) |
| Ambiguous step | error | error | error | error |
| DocString / DataTable | last argument | last argument | `context.text` / `context.table` | last argument |
| Scenario Outline | expanded row matched | expanded row matched | expanded row matched | expanded row matched |
| Step scope | global (glue) | global (bindings) | global | feature class + `shared_steps` |
| State | new instance per scenario + DI | context injection | `context` object | new instance per test |
| Hooks | `@Before` / `@After` | `[BeforeScenario]` / `[AfterScenario]` | `before_scenario` | `@Before` / `@After` |
| When matched | runtime | runtime | runtime | **build time** |
| Generated tests | none | yes, calls `testRunner.Given("text")` | none | yes, **direct method calls** |

The last two rows are bdd_flutter's deliberate difference: undefined,
ambiguous or mistyped steps fail at build or compile time, and IDE navigation
from a test goes straight to the step method.

## Open questions

- Where `--write-snippets` appends when `_steps.dart` has several classes or
  `part` files: last class of the expected name, otherwise error?
- Sharing state between the feature class and shared classes: constructor
  injection of a shared context object, or leave it to users?
- Tag-filtered hooks and per-feature hooks (`setUpAll`) in 3.0 or later?
- Should `{float}` snippets use `double` or `num`?
- Keep the `steps_suffix` config, or derive the class from the file?
- Performance of analyzer on large projects: read only `_steps.dart` files
  next to features.
