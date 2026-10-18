## 2.0.0

### Breaking

- Minimum Dart SDK is now 3.8.0 (required by `cucumber_gherkin`)

### Features

- `.feature` files are now parsed by the official [`cucumber_gherkin`](https://pub.dev/packages/cucumber_gherkin) parser and mapped from [`cucumber_messages`](https://pub.dev/packages/cucumber_messages) types (#6)
- Supports `But` and `*` steps, `Scenario Outline`, `Rule` (with its own `Background`), several `Examples` blocks, several tags on one line, comments, escaped `\|` in tables and non-English keywords (`# language: fr`)
- Invalid `.feature` files are reported with line and column and skipped; other features still build
- Steps carry a `keywordType` (context, action, outcome, conjunction)
- Doc strings and data tables are passed to step methods as `String docString` and `List<List<String>> dataTable`; `<column>` placeholders inside them are filled from the current example row

### Bug Fixes

- Fix example values being passed in table-column order instead of step-text order, which silently swapped arguments when the columns were ordered differently from the placeholders
- Fix example values containing `'` or `$` producing invalid generated code
- Remove a stray space in generated unit-test step calls (`scenario.step( value)`)
- Fix duplicate method parameters (compile error) when a step uses the same placeholder twice, e.g. `from "<city>" and back to "<city>"`
- Fix a crash (`Null check operator used on a null value`) when a Scenario Outline has several `Examples` blocks with different columns; a column missing from a block keeps its `<column>` text
- Fix generated calls missing arguments (compile error) when a `<placeholder>` has no matching example column, or appears in a plain Scenario or Background; its literal `<name>` text is passed
- Fix duplicate method declarations (compile error) when the same step text appears twice in a scenario or background
- `build` now exits with code 1 when any `.feature` file fails to parse, so CI catches invalid Gherkin
- Before regenerating a scenario file because a scenario changed, the old file is copied to `.bdd_scenarios.dart.bak` so step code can be recovered

### Example

- Add `test/cart/cart.feature`: Rule with its own Background, Scenario Outline with two Examples blocks, `But` and `*` steps, several tags on one line
- Add `test/compteur/compteur.feature`: French keywords
- Add `test/stress/stress.feature`: doc strings, data tables (including example placeholders inside them), repeated placeholders, tags on Examples, symbols in step text

### Notes

- Scenario hashes are unchanged, so existing manifests stay valid and no files are regenerated after upgrading. The exception is features that use a doc string or data table: those steps get new parameters, so the feature's whole `.bdd_scenarios.dart` file is regenerated once and the step code in it is overwritten. Commit before upgrading and copy your step code back
- Non-ASCII letters are dropped from generated names (`Incrémenter` → `IncrMenterScenario`), since Dart identifiers are ASCII only

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
