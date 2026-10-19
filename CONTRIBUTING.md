# Contributing to bdd_flutter

Thanks for helping. This guide covers how the code is organized and the conventions it follows. For what the package does from a user's point of view, see the [README](README.md).

## Setup

```bash
dart pub get
dart analyze
dart test                  # package tests (pure Dart)
```

The `example/` project is a Flutter app that exercises the generator end to end:

```bash
cd example
dart run bdd_flutter build      # regenerate from the .feature files
flutter test                    # run the generated tests
dart run bdd_flutter test       # same, with the Feature/Scenario report
```

After changing the generator, run `build` in `example/` and commit the regenerated `.bdd_steps.dart` and `.bdd_test.dart` files with your change, so reviewers can see the effect on real output.

## How generation works

The CLI entry point is `bin/bdd_flutter.dart`. A `build` runs:

```
BDDCLI.run(args)
  → BDDController.generateFeatureTestCases()
    → ConfigParser.loadConfig()                 # .bdd_flutter/config.yaml
    → FeatureParser.parseFeature(path)          # cucumber_gherkin → GherkinDocument
      → GherkinMapper.toFeature(document)       # GherkinDocument → Feature
    → StepsCatalog.of(feature)                  # distinct step patterns → StepMethods
    → StepsContractBuilder.build(...)           # → <name>.bdd_steps.dart (always rewritten)
    → TestFileBuilder.build(...)                # → <name>.bdd_test.dart (always rewritten)
    → StepsStubBuilder.build(...)               # → <name>_steps.dart (only if missing)
    → checkStepsFile(...)                       # warn about missing or unused steps
    → DartFormatCommand.formatFiles(...)        # the SDK's `dart format`
```

The tool never writes to a `_steps.dart` file that already exists. That file belongs to the user.

`migrate` (`MigrateController`) moves 1.x projects: `LegacyScenariosFile` reads a 1.x `.bdd_scenarios.dart` with a brace- and string-aware scanner (no `analyzer`), `LegacyCodeMapper` maps its method bodies onto the 2.0 methods using the 1.x naming rules in `LegacyNames`, and the old file is renamed to `.bak`.

## Code layout

Clean Architecture under `lib/src/`:

| Folder | Contents |
| --- | --- |
| `domain/` | Feature, Rule, Scenario, ExamplesTable, Step, Background, Decorator, ValueType, StepPattern/StepSlot, StepMethod, FeatureFiles (paths and class names), BDDConfig |
| `infrastructure/parsers/` | FeatureParser (wraps `cucumber_gherkin`), GherkinMapper, ConfigParser |
| `infrastructure/steps/` | StepPatternParser, columnTypes, StepsCatalog |
| `infrastructure/builders/` | StepsContractBuilder, StepsStubBuilder, TestFileBuilder, ScenarioSettings (test kind, skip, tags), stepArguments |
| `infrastructure/migration/` | 1.x → 2.0 migration |
| `infrastructure/formatting/` | CodeFormatter: `DartFormatCommand`, and `NoFormatting` for tests |
| `extensions/` | Name building (`StringX`) and accent folding (`latin_fold.dart`) |
| `presentation/cli/` | Argument parsing |
| `presentation/controllers/` | BDDController (build), MigrateController, BuildReport, steps file check |
| `presentation/reporter/` | The `test` command and its report |

`GherkinMapper` is the only code that touches `cucumber_messages` types, so an upstream change stays in one file.

## Step patterns

A step's pattern key is its text with each value replaced by a type marker, plus `+docString` / `+dataTable` when it has them. Steps with the same key share one method, whatever their keyword.

Values (slots) are:

- `"quoted text"`, including `"<column>"`: `String`;
- a bare `<column>` that matches an Examples column: typed from the column (`num` if every value is a number, `bool` if all are `true`/`false`, else `String`);
- a standalone number whose `num.parse(v).toString() == v`: `num`.

A number next to a letter, `:`, `$`, `%`, `,`, `/` or `-` stays part of the text, so `3rd`, `09:00` and `$10.00` are never changed. When in doubt, leave a value in the text: a missed slot costs a duplicate method, a wrong slot loses data.

## Generated code

```dart
// cart.bdd_steps.dart (generated)
abstract interface class ShoppingCartStepsContract {
  Future<void> iAddAtEach(num quantity, String item, num price);
}

// cart_steps.dart (written by the user)
class ShoppingCartSteps implements ShoppingCartStepsContract {
  late Cart cart;

  @override
  Future<void> iAddAtEach(num quantity, String item, num price) async => cart.add(item, price.toDouble(), quantity.toInt());
}

// cart.bdd_test.dart (generated)
test('Add', () async {
  final steps = ShoppingCartSteps();          // widget tests: ..tester = tester
  await steps.iAddAtEach(2, 'apple', 1.5);
});
```

Scenario Outlines become a `group(scenarioName)` with one test per row; Rules become `group('Rule: name')`. Every generated file name matches `*.bdd_*.dart`, and a user file never does.

## Coding conventions

- PascalCase for classes, camelCase for variables and functions, snake_case for file names
- Declare explicit types; avoid `dynamic`
- One public class or function per file
- Keep functions short (under about 20 lines) with a single purpose
- Prefer composition over inheritance
- Use early returns to avoid deep nesting
- Tests follow Arrange-Act-Assert
- Format with `dart format`; the page width is 120 (set in `analysis_options.yaml`)

## Pull requests

- `dart analyze` and `dart test` pass, and `flutter test` passes in `example/`
- New behavior has tests; generator changes include the regenerated example files
- User-visible changes get a line in `CHANGELOG.md`, and the README if usage changes
