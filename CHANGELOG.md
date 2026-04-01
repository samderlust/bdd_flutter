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
