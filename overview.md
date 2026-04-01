# Project Overview

This is an overview and guidance for developing `bdd_flutter` package and the structure of the code.

The `bdd_flutter` package is a powerful tool for Behavior-Driven Development (BDD) in Flutter. It simplifies the process of writing and maintaining tests by automatically generating test files from Gherkin feature files.

## Key Features

- **Automatic Test Generation**: Write your tests in Gherkin syntax, and let the package generate the corresponding Dart test files.
- **Incremental Updates**: Preserve your custom code during test file regeneration.
- **Customizable**: Configure the package to suit your project's needs.
- **Support for Both Widget and Unit Tests**: Choose the type of tests you want to generate.
- **Test Reporter**: Optionally enable a test reporter to get detailed test results.

## Flowchart

```mermaid
flowchart TD
    n1[".feature file"] --> n2["parsing feature file"]
    n2 --> n13["pasring .manifest files"]
    n3["Feature"] --> n4["content parsing"]
    n5(["start parsing feature file"]) --> n1
    n4 --> n6["ScenariosContent"] & n7["TestCasesContent"]
    n6 --> n8["writing file"]
    n7 --> n8
    n8 --> n9["scenarios.dart"] & n10["test.dart"] & n16["Update manifest file"]
    n9 --> n11(["END"])
    n10 --> n11
    n14["Scenarios and test files exists?"] -- YES --> n15(["Skip Feature"])
    n16 --> n12[".manifest"]
    n12 --> n14
    n13 --> n12
    n14 -- NO --> n3
    n15 --> n11
    n1@{ shape: lean-l}
    n3@{ shape: lean-l}
    n6@{ shape: lean-r}
    n7@{ shape: lean-r}
    n9@{ shape: lean-r}
    n10@{ shape: lean-r}
    n16@{ shape: rect}
    n14@{ shape: diam}
    n12@{ shape: lean-r}

```

## Project layout

1. Parsing functionality

- Feature file parsing: parse feature file content into a Feature object
  - location: `lib/src2/feature/parsing/feature_parser.dart`
- Scenario file parsing: parse scenario classes from a Dart file into Content object
  - location: `lib/src2/feature/parsing/scenario_parser.dart`
- Test file parsing: parse test cases from a Dart file into Content object
  - location: `lib/src2/feature/parsing/test_case_parser.dart`

2. Content:

- Scenario content:
  - parsed from scenario Dart file
  - to be used to generate scenario Dart file
- Test case content: parsed from test file
  - to be used to generate test file
  - to be used to generate test file

3. File Processing

   - to read and write files

4. Builder

   - to parse CMD

## Project Structure

- Domain layer
  - Feature
  - Scenario
  - Step
  - Content
  - Decorator
- Parsing layer
  - FeatureParser
  - ScenarioParser
  - TestCaseParser
- File processing layer
  - DartFileWriter
  - DartFileReader
- Builder layer
  - BuildCommand
  - CommandParser
- CLI layer
  - CLILogger
  - CLIHelp
- Config layer
  - ConfigManager
- Manifest layer
  - ManifestManager
  - ManifestParser
