## 2.0.0-beta.1

A beta of 2.0: please try it, including `migrate` on a 1.x project, and report anything odd, especially generated names. Naming rules, file names and the contract shape can still change until 2.0.0; after that, changing them would break your steps files.

2.0 changes the shape of the generated code. Run `dart run bdd_flutter migrate` once to move a 1.x project; see "Upgrading from 1.x" in the README.

### Breaking

- Step code moves from `.bdd_scenarios.dart` (one class per scenario, edited by you and appended to by the tool) to three files per feature:
  - `<name>.bdd_steps.dart`: a generated `abstract interface class <Feature>StepsContract`, rewritten on every build
  - `<name>_steps.dart`: your `<Feature>Steps implements <Feature>StepsContract`, created once and never touched again
  - `<name>.bdd_test.dart`: the generated tests
- One steps class per feature, with one method per distinct step. Background, Rule background and scenario steps share it, so state lives in normal fields instead of top-level variables
- Quoted text and standalone numbers in step text become typed parameters: `I add 2 "apple"` is `iAdd(num number, String text)` instead of `iAdd2Apple()`. Steps that differ only in these values share a method
- Outline columns are typed: `num` when every value is a number Dart prints back unchanged, `bool` for `true`/`false`, otherwise `String`
- Widget tests get the `WidgetTester` through a `tester` field set by the generated test, not as a method parameter
- Unimplemented steps throw `UnimplementedError` instead of passing silently
- Minimum Dart SDK is 3.8.0 (required by `cucumber_gherkin`)
- Removed: the manifest (`.bdd_flutter/manifest.yaml`), incremental append and `build --force`; `build` always rewrites generated files and never touches yours
- Tags that are not valid `dart test` tag names, such as 1.x's `@className("X")`, are ignored
- Config: `scenario_suffix` is replaced by `steps_suffix` (default `Steps`); `scenario_suffix` is only read by `migrate`. `additional_imports` now go into new `_steps.dart` files

### Features

- `.feature` files are parsed by the official [`cucumber_gherkin`](https://pub.dev/packages/cucumber_gherkin) parser and mapped from [`cucumber_messages`](https://pub.dev/packages/cucumber_messages) types (#6)
- Supports `But` and `*` steps, `Scenario Outline`, `Rule` (with its own `Background`), several `Examples` blocks, several tags on one line, comments, escaped `\|` in tables and non-English keywords (`# language: fr`)
- Scenario Outlines generate one test per example row, in a group named after the scenario; each row runs the Background with fresh state, and a failing row no longer hides the others
- `Rule:` blocks become `group('Rule: …')`, and a Rule's Background runs after the feature's
- Doc strings and data tables are passed as `String docString` and `List<List<String>> dataTable`, with `<column>` placeholders filled per row
- Gherkin tags are passed to `test()`/`testWidgets()` as `tags:`, merged from feature, rule, scenario and Examples; `build` lists them for `dart_test.yaml`
- `@skip` on a feature, rule, scenario or Examples block generates `skip: true`
- `generate_widget_tests` now applies to scenarios without `@unitTest`/`@widgetTest`; the closest decorator wins (scenario, then rule, then feature)
- Generated files are formatted with the SDK's `dart format`, using your package's style and page width
- `build` reports steps your `_steps.dart` lacks and steps it overrides that the feature no longer has
- New `migrate` command carries 1.x step code into the new steps files
- Steps used by several features go into a generated `SharedStepsContract` (`test/shared.bdd_steps.dart`) and a `mixin SharedSteps` you implement once (`test/shared_steps.dart`). New steps classes mix it in; feature contracts still declare shared steps, so a step becoming shared never breaks existing classes
- `bdd_flutter test` report: Scenario Outline rows and Rules are nested, skipped tests are shown and counted, failures point at the line in your steps file, features are sorted by path, durations appear only for failed and slow tests, and colors follow `NO_COLOR` and the terminal
- Accented letters are folded in generated names (`Incrémenter` → `Incrementer`, Vietnamese included); text with no Latin letters gets a stable hashed name. No extra dependency: the folding table is built in. Names never collide with Dart keywords or `Object` members
- Invalid `.feature` files are reported with line and column and skipped; `build` exits with code 1 so CI catches them
- Steps carry a `keywordType` (context, action, outcome, conjunction)

### Bug Fixes

- Skipped tests were listed in the test report as nameless passing tests under an empty "Test File:" heading, and counted as passed
- Scenario Outline rows no longer share state set up by the Background
- Example values containing `'` or `$` no longer produce invalid code, in arguments and test names
- Numbers such as `1.50`, `02134` or `$10.00` are never turned into a different value

### Example

- Every example feature now has working steps, and `login.feature` is a real widget test with `mocktail`
- Add `test/cart/cart.feature` (Rule, two Examples blocks, `But` and `*`), `test/compteur/compteur.feature` (French keywords) and `test/stress/stress.feature` (doc strings, data tables, repeated placeholders, tags on Examples, symbols in step text)
- Add `dart_test.yaml` declaring the example's tags
- `test/complex/complex1.feature` is marked `@skip`: it shows generated names for long, real-world step text

## 1.1.1

### Features

- `dart run bdd_flutter test` now runs all test files (BDD and regular), not just `.bdd_test.dart`
- Separate report sections: **BDD Test Report** (grouped by Feature/Scenario) and **Non-BDD Test Report** (grouped by test file and group name with indentation)
- Combined summary at the bottom with total pass/fail counts

### Tests

- Add integration tests for `BDDController` incremental build (rename, remove, modify, delete, force, append scenarios)

## 1.1.0

### Bug Fixes

- Fix class name generation for names starting with digits (e.g., `"123 login"` → `X123LoginScenario`)
- Fix class name generation for names with special characters (hyphens, punctuation now stripped)
- Fix method name generation for steps starting with digits (leading digits stripped)
- Fix `snakeCaseToCamelCase` crash on leading/trailing underscores
- Return safe fallback names (`Unnamed`, `unnamed`, `step`) instead of empty strings for edge cases
- Fix Background class name not sanitized — feature names with spaces/hyphens (e.g., `"Form auto-save"`) produced invalid Dart class names
- Fix incremental build skipping regeneration when generated files are deleted but manifest entry still exists
- Fix incremental build appending instead of regenerating when scenarios are removed, renamed, or modified — caused broken test files referencing non-existent classes

### Tests

- Add comprehensive unit tests for `StringX` extensions (PascalCase, snakeCaseToCamelCase, toSnakeCase)
- Add unit tests for `Step.methodName` edge cases (digits, special chars, empty text, params)
- Add unit tests for `Scenario` class name generation, decorator resolution, and hash consistency
- Add unit tests for `Decorator` parsing and set helpers

## 1.0.0

### BREAKING CHANGES

- Removed `build_runner` dependency entirely — use `dart run bdd_flutter build` instead
- Removed `--no-widget-test` and `--new-only` CLI flags
- Configuration moved from `build.yaml` to `.bdd_flutter/config.yaml`
- Generated file extensions changed from `.bdd_scenarios.g.dart` to `.bdd_scenarios.dart` and `.bdd_test.g.dart` to `.bdd_test.dart`

### Features

- New standalone CLI: `dart run bdd_flutter build` and `dart run bdd_flutter test`
- Incremental test generation with manifest tracking (only regenerates changed scenarios)
- `--force` flag to regenerate all files
- `test` command with formatted Feature/Scenario report output
- Custom test directory via `test_dir` config option
- Custom scenario class suffix via `scenario_suffix` config option (e.g., `Steps` instead of `Scenario`)
- Additional imports support via `additional_imports` config option
- Background steps support
- `@unitTest` / `@widgetTest` decorators at feature and scenario level
- Scenario-level Examples tables for parameterized tests

### Improvements

- Clean Architecture restructure (domain, infrastructure, presentation layers)
- Instance-based scenario classes (supports `late` fields for shared state)
- Comprehensive documentation across all layers

## 0.3.0

- remove `build_runner` dependency
- add custom CLI
- `dart run bdd remane` to remove `.g` from generated files extension
- `dart run bdd build` to generate files from feature files

## 0.2.0

- change output files extension to `.bdd_scenarios.g.dart` and `.bdd_test.g.dart`
- add `ignore_features` option to `build.yaml`
- fix example
- fix import file name
- update readme

## 0.1.5

- fix import file name

## 0.1.4

- fix builder with examples
- add ignore decorator on feature

## 0.1.3

- fix builder issue with examples
- restructure code

## 0.1.2

- add `@disableReporter` and `@enableReporter` decorators
- fix build_runner error
- improve documentation
- change log to stdout
- update readme

## 0.1.1

- add `@className` decorator
- fix build_runner error

## 0.1.0

- refactor to use factory pattern
- improve code readability
- improve documentation

## 0.0.1

- Initial release
