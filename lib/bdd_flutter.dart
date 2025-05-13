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
/// * Incremental generation to preserve user-written code
/// * Configuration in .bdd_flutter/config.yaml
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
/// # Default: Incremental update (process new and modified scenarios)
/// dart run bdd_flutter build
///
/// # Force regenerate all files
/// dart run bdd_flutter build --force
///
/// # Only process new feature files
/// dart run bdd_flutter build --new-only
/// ```
///
/// ## Configuration
///
/// Configuration is stored in `.bdd_flutter/config.yaml`:
/// ```yaml
/// generate_widget_tests: true
/// enable_reporter: false
/// ignore_features:
///   - test/features/login.feature
///   - test/features/registration.feature
/// ```
///
/// Command-line arguments override config file settings:
/// ```bash
/// dart run bdd_flutter build --no-widget-tests --enable-reporter --ignore login.feature
/// ```
///
/// ## Generation Modes
///
/// The package supports three generation modes:
///
/// 1. **Incremental Update** (default):
///    - Processes new and modified scenarios
///    - Preserves user-written code
///    - Tracks changes in .bdd_flutter/manifest.yaml
///
/// 2. **Force Regenerate** (--force):
///    - Regenerates all test files
///    - Overwrites existing files
///    - Use with caution
///
/// 3. **New Files Only** (--new-only):
///    - Only processes new feature files
///    - Skips existing files
///    - Useful for initial setup
///
/// ## Additional Information
///
/// For more information, visit the [documentation](https://example.com/bdd_flutter).
