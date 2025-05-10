library bdd_flutter;

export 'src/feature/report/test_reporter.dart' show BDDTestReporter;

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
/// * Ignore specific generated files using .bdd_config.yaml
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
/// 3. Run the generator to create test files:
/// ```bash
/// dart run bdd_flutter build
/// ```
///
/// ## Configuration
///
/// You can configure the generator in `.bdd_config.yaml`:
/// ```yaml
/// generate_widget_tests: true
/// enable_reporter: false
/// ignore_features:
///   - test/features/login.feature
///   - test/features/registration.feature
/// ```
///
/// Or use command-line arguments:
/// ```bash
/// dart run bdd_flutter build --no-widget-tests --enable-reporter --ignore login.feature
/// ```
///
/// ## Additional Information
///
/// For more information, visit the [documentation](https://example.com/bdd_flutter).
