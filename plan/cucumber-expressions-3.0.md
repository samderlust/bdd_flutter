# bdd_flutter 3.0: Cucumber Expressions

Status: proposal · Discussion: [#11](https://github.com/samderlust/bdd_flutter/issues/11) · Follows [#6](https://github.com/samderlust/bdd_flutter/issues/6)

## Summary

3.0 replaces the generated steps contract with Cucumber Expressions written in
the user's steps file. `build` matches every feature step against those
expressions with the official
[`cucumber_expressions`](https://pub.dev/packages/cucumber_expressions)
package, generates tests that call the matched methods, and prints a snippet
for every step nothing matches. Steps used by several features stay in the
shared steps mixin, as in 2.x. This is a breaking change:
expressions are the default, `steps_mode: contract` in the config keeps the
2.x behaviour, and `migrate` moves 2.x (and 1.x) projects over without
changing method bodies.

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

### Keeping 2.x: `steps_mode`

```yaml
# .bdd_flutter/config.yaml
steps_mode: contract   # 2.x behaviour; default is `expressions`
```

3.0 is still a breaking release: expressions are the default, so a 2.x project
either adds this line or runs `migrate`. The option exists so teams can upgrade
the package without changing their steps at the same time.

The cost is two ways of connecting steps to code. It stays small because only
step calls differ: `TestFileBuilder` takes a `StepCalls`, implemented by
`CatalogStepCalls` (2.x contract) and `ExpressionStepCalls` (3.0). Gherkin
parsing, test layout, tags, formatting and the `test` command are shared. An
unknown `steps_mode` value is an error, so a typo never switches a project's
mode. Whether contract mode is removed in a later major release is decided by
how much it is used.

## Files

| File | 2.x | 3.0 |
|---|---|---|
| `cart.feature` | Gherkin | unchanged |
| `cart.bdd_steps.dart` | generated contract | **not generated** (still generated with `steps_mode: contract`) |
| `cart_steps.dart` | user-owned, `implements CartStepsContract` | user-owned, methods annotated with `@Given`/`@When`/`@Then` (or `@StepDefinition`) |
| `cart.bdd_test.dart` | generated | generated, same shape |
| `test/shared_steps.dart` | `mixin SharedSteps`, created the first time a step is used by several features; feature classes mix it in | same file and mixin, methods annotated with `@Given`/`@When`/`@Then` |

## Example

```gherkin
Feature: Cart
  Scenario: Pay
    Given the order is shipped
    And I have 2 cucumbers in my belly
    When I pay $10.00
```

### Snippets for undefined steps

`build` prints a snippet for every undefined step, with the class to add it
to, and never writes it: like Cucumber, it suggests and the user pastes.
Printed snippets look like these (the steps file starts as an empty class):

```dart
class CartSteps {
  @Given('the order is shipped')
  Future<void> theOrderIsShipped() async => throw UnimplementedError();

  @Given('I have {int} cucumbers in my belly')
  Future<void> iHaveCucumbersInMyBelly(int int1) async =>
      throw UnimplementedError();

  @When(r'I pay ${float}')
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

  @Given('I have {int} cucumber(s) in my belly/stomach')
  Future<void> iHaveCucumbers(int count) async { ... }

  @When('I pay {money}')
  Future<void> iPay(Money amount) async { ... }
}
```

`@Given`, `@When` and `@Then` are aliases of the keyword-free
`@StepDefinition`: matching ignores the keyword, as in Cucumber, so
`And I pay $10.00` and `Then I pay $10.00` both match `@When('I pay {money}')`.

### Name clashes

- The keyword-free annotation is `StepDefinition`, not `Step`: Flutter's
  `material.dart` exports a `Step` (for `Stepper`), so `@Step` broke every
  steps file that imports it.
- mocktail exports a class `When`. Steps files import mocktail with
  `hide When` (its `when(...)` function is unaffected); `migrate` and new
  steps files add it. Prefixed imports (`@bdd.When`) also work.

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

2.x already shares steps between features: a step used by more than one
feature goes into `mixin SharedSteps` in `shared_steps.dart` at the root of
the test directory (named after `steps_suffix`), created once with stubs, and
every feature steps class mixes it in. 3.0 keeps that model and adds
expressions to it:

```dart
// test/shared_steps.dart
mixin SharedSteps {
  WidgetTester get tester; // only when a shared step needs it

  @Given('I am logged in as {string}')
  Future<void> iAmLoggedInAs(String user) async { ... }
}
```

```dart
// test/cart/cart_steps.dart
class CartSteps with SharedSteps {
  @When('I pay {money}')
  Future<void> iPay(Money amount) async { ... }
}
```

`build` reads the mixin and the feature's class and matches each step against
the feature's class first, then the mixin. Everything runs on one object, so
the generated test is unchanged:

```dart
test('Pay', () async {
  final steps = CartSteps();
  await steps.iAmLoggedInAs('ann');
  await steps.iPay(CartSteps.money(r'$10.00'));
});
```

- **One object, shared state for free.** Shared steps keep their state in the
  mixin's fields, which live on the feature's steps object; nothing like
  Cucumber's DI is needed.
- **Override.** A definition in the feature's class wins over the mixin, so a
  feature can replace a shared step.
- **A shared step on a class that does not mix it in** is a build error asking
  for `with SharedSteps`, since the generated call would not compile.
- **Snippets.** An undefined step used by several features gets its snippet
  for `SharedSteps` (in `shared_steps.dart`); one used by a single feature gets
  it for that feature's class; one defined in another feature's class is
  suggested to move to `SharedSteps`. The hint says to create the file or add
  `with SharedSteps` when needed; `build` never creates `shared_steps.dart`.
- **Parameter types and hooks** declared on the mixin apply to every class that
  mixes it in.
- Several shared mixins (e.g. `AuthSteps`, `CartSharedSteps`) are possible
  later by reading every mixin a class uses; 3.0 keeps the single
  `SharedSteps` mixin of 2.x.

## Hooks

2.x has no hooks; `Background` steps are inlined into each test. 3.0 adds
scenario hooks as annotated instance methods, on the feature class or the
`SharedSteps` mixin:

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

Order: `@Before` hooks of the mixin, then of the feature class; `@After` in
reverse. Tag-filtered hooks (`@Before(tags: '@db')`) and per-feature hooks
(`setUpAll`) can follow later.

## Pipeline

```
BDDCLI.run(args)
  → BDDController.generateFeatureTestCases()
    → ConfigParser.loadConfig()                 # + steps_mode (contract → 2.x pipeline)
    → FeatureParser.parseFeature()              # unchanged
      → GherkinMapper.toFeature()               # unchanged
    → StepsFileReader.read(_steps.dart,         # NEW: analyzer → @Given/@When/@Then/@StepDefinition,
                           shared_steps.dart)   #      @ParameterType, @Before/@After
    → StepMatcher.match(step)                   # NEW: ExpressionFactory
        feature class, then SharedSteps mixin
        1 match  → call with converted arguments
        2+       → fail('Ambiguous step: ...') in the test + reported
        0        → fail('Undefined step: ...') + snippet
    → TestFileBuilder.build(...)                # hooks, then calls on one steps object
    → UndefinedSteps.hints()                    # NEW: SnippetGenerator over
                                                #      CucumberExpressionGenerator; printed only
    → checkStepsFile(...)                       # reworked diagnostics
    → DartFormatCommand.formatFiles(...)        # unchanged
```

Used only in contract mode: `StepPatternParser`, `columnTypes`,
`StepsCatalog`, `StepsContractBuilder`, `StepsStubBuilder`,
`SharedStepsBuilder` and `SharedMixin`.

## Decisions

| # | Topic | Decision |
|---|---|---|
| 1 | Annotation | `@Given`/`@When`/`@Then`, aliases of the keyword-free `@StepDefinition` (not `Step`: Flutter clash). Matching ignores the keyword, as in Cucumber. |
| 2 | Custom types | `@ParameterType(regex)` on a static method taking `String`, as in Cucumber-JVM; the type name defaults to the method name (`name:` overrides it). The generated test calls `Steps.name('raw')`. |
| 3 | Built-in types | Cucumber's `{int}`, `{float}`, `{word}`, `{string}`, `{}`, plus `{num}` and `{bool}` registered by bdd_flutter so migrated signatures stay `num` and `bool` (2.x types numbers and `true`/`false` Examples columns that way). |
| 4 | Snippets | Printed by `build`, as in Cucumber, with the class to add each one to (`SharedSteps` when several features use the step) and `UnimplementedError` bodies. `build` never writes them: the generated test already compiles with `fail('Undefined step: ...')`. |
| 5 | Scenario Outline | Each Examples row's expanded text is matched, as in Cucumber. |
| 6 | No match | Snippet + build warning. |
| 7 | Several matches | Build error listing the expressions. |
| 8 | Reading the steps file | `analyzer`; only string-literal expressions and regexes. |
| 9 | Public API | `package:bdd_flutter/bdd_flutter.dart` exports `Given`, `When`, `Then`, `StepDefinition`, `ParameterType`, `Before` and `After`, with no CLI code. |
| 10 | Migration | `migrate` goes from 1.x or 2.x straight to 3.0. |
| 11 | 2.x | `steps_mode: contract` keeps the 2.x pipeline; default `expressions`; unknown values are an error. |
| 12 | Shared steps | Kept from 2.x: `mixin SharedSteps` in `shared_steps.dart`, mixed into feature classes. Feature class matched first, then the mixin; one steps object per test. |
| 13 | Hooks | `@Before` / `@After` instance methods; `@After` registered with `addTearDown`. |

## Argument values in generated tests

| Type | Step text | Generated argument |
|---|---|---|
| `{int}` | `2` | `2` |
| `{float}` | `1.5` | `1.5` (`1` → `1.0`) |
| `{num}` | `2` | `2` |
| `{bool}` | `true` | `true` |
| `{string}` | `"apple"` / `'apple'` | `'apple'` (escaped) |
| `{word}`, `{}` | `apple` | `'apple'` |
| custom | `shipped` | `CartSteps.status('shipped')` |
| DocString / DataTable | | appended after the expression's parameters, as in 2.x |

## Migration (`dart run bdd_flutter migrate`)

A 2.x pattern key is already close to an expression:

```
2.x key:      I add {num} {string} at {num} each
3.0:          @When('I add {num} {string} at {num} each')
```

For each feature:

1. Add `@Given`/`@When`/`@Then('<key as expression>')` to every method in `_steps.dart`, after the keyword of its first step (`And`, `But`, `*` take the previous one; `@StepDefinition` when there is none).
2. Escape metacharacters in literal text: `(`, `)`, `{`, `}`, `/`, `\`.
3. Bare string `<column>` slots (unquoted in the step) become `{word}`, or
   `{}` when a value contains spaces.
4. Remove `implements XStepsContract` and `@override`.
5. Delete `.bdd_steps.dart`.
6. Strip `+docString` / `+dataTable` from the key; the trailing argument stays.

The same steps run on `shared_steps.dart`: each `SharedSteps` method gets the
annotation of its 2.x shared key; the `with SharedSteps` clauses stay.

Signatures and method bodies are unchanged. 1.x projects go through the
existing 1.x → 2.x mapping first, in the same run.

## Diagnostics

- Step with no matching expression → warning + snippet.
- Step matching several expressions in the feature's class, or several in the mixin → error.
- Step matched only by `SharedSteps` in a class without `with SharedSteps` → error.
- Expression no step uses → warning.
- Parameter count or type that disagrees with the expression → error.
- Unknown parameter type (`{colour}`) or invalid expression → error with position.

## Work order

1. Public annotations (`Given`, `When`, `Then`, `StepDefinition`, `ParameterType`, `Before`, `After`) and exports.
2. `StepsFileReader` (analyzer), for the feature's steps file and `shared_steps.dart` (classes and mixins).
3. `StepMatcher` over `ExpressionFactory` with a type registry (built-ins + `{num}` + `{bool}` + custom), feature class first, then the shared mixin.
4. `TestFileBuilder`: call hooks, turn matched values into Dart literals or `Steps.type('raw')`.
5. `SnippetGenerator` over `CucumberExpressionGenerator`; `build` prints snippets with where to add them.
6. Wire `steps_mode` into `build`: expressions by default, the 2.x pipeline for `contract`; rework `checkStepsFile` for expressions.
7. `migrate` to 3.0.
8. Migrate `example/`; add `{status}`, `{money}`, a shared step and hooks.
9. README, CHANGELOG, migration guide, CLAUDE.md.

1–3 are the core; 4–7 depend on them; 8–9 last.

Status: 1–9 are done: `build` follows `steps_mode` and prints snippets for
undefined steps, `migrate` moves 2.x projects (the example included) and the
docs describe 3.0. `--write-snippets` was dropped: every Cucumber
implementation only prints snippets, and the generated tests compile without
them.

## Comparison with other BDD tools

| Concept | Cucumber (JVM/JS/Ruby) | Reqnroll / SpecFlow (.NET) | Behave / pytest-bdd | bdd_flutter 3.0 |
|---|---|---|---|---|
| Step definition | annotation or function + expression | attribute + expression | decorator + parse/regex | annotation + expression |
| Expression syntax | Cucumber Expressions | Cucumber Expressions or regex | `parse` format | Cucumber Expressions |
| Keyword | ignored when matching | keyword-specific by default (`[StepDefinition]` matches any) | keyword-specific | ignored (`@Given`/`@When`/`@Then`/`@StepDefinition`) |
| Custom types | `@ParameterType` / `defineParameterType` | `[StepArgumentTransformation]` | `register_type` | `@ParameterType` |
| Undefined step | snippet printed | snippet suggested by the IDE | error | snippet printed, with the class to add it to |
| Ambiguous step | error | error | error | error |
| DocString / DataTable | last argument | last argument | `context.text` / `context.table` | last argument |
| Scenario Outline | expanded row matched | expanded row matched | expanded row matched | expanded row matched |
| Step scope | global (glue) | global (bindings) | global | feature class + `SharedSteps` mixin |
| State | new instance per scenario + DI | context injection | `context` object | one object per test (class + mixin) |
| Hooks | `@Before` / `@After` | `[BeforeScenario]` / `[AfterScenario]` | `before_scenario` | `@Before` / `@After` |
| When matched | runtime | runtime | runtime | **build time** |
| Generated tests | none | yes, calls `testRunner.Given("text")` | none | yes, **direct method calls** |

The last two rows are bdd_flutter's deliberate difference: undefined,
ambiguous or mistyped steps fail at build or compile time, and IDE navigation
from a test goes straight to the step method.

## Open questions

- Tag-filtered hooks and per-feature hooks (`setUpAll`) in 3.0 or later?
- `{float}` snippets use `double`, as the matched value is a `double`.
- Keep the `steps_suffix` config, or derive the class from the file?
- Performance of analyzer on large projects: read only `_steps.dart` files
  next to features.
