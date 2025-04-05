import 'package:bdd_flutter/src/builder.dart';
import 'package:bdd_flutter/src/domain/bdd_options.dart';
import 'package:build/build.dart';

/// A Flutter package for Behavior-Driven Development (BDD) testing.
///
/// This package allows you to write tests in a BDD style using feature files
/// and automatically generates the corresponding Dart test files.
///
/// ## Features
///
/// * Parse Gherkin-style feature files
/// * Generate test files automatically
/// * Support for both widget and non-widget tests
/// * Customizable test generation options
///
/// ## Getting Started
///
/// 1. Add the package to your `pubspec.yaml`:
/// ```yaml
/// dev_dependencies:
///   bdd_flutter: ^1.0.0
/// ```
///
/// 2. Create a feature file (e.g., `test/features/login.feature`):
/// ```gherkin
/// Feature: Login
///   As a user
///   I want to log in to the application
///   So that I can access my account
///
///   Scenario: Successful login
///     Given I am on the login screen
///     When I enter valid credentials
///     And I tap the login button
///     Then I should see the home screen
/// ```
///
/// 3. Run the build_runner to generate test files:
/// ```bash
/// flutter pub run build_runner build
/// ```
///
/// ## Configuration
///
/// You can configure the builder in your `build.yaml`:
/// ```yaml
/// targets:
///   $default:
///     builders:
///       bdd_flutter|bdd_test_builder:
///         options:
///           generate_widget_tests: true
/// ```
///
/// ## Additional Information
///
/// For more information, visit the [documentation](https://example.com/bdd_flutter).

Builder bddTestBuilder(BuilderOptions options) {
  final config = options.config;
  final generateWidgetTests = config['generate_widget_tests'] as bool? ?? true;
  final bddOptions = BDDOptions(generateWidgetTests: generateWidgetTests);
  return BDDTestBuilder(options: bddOptions);
}
