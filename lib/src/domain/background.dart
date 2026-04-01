import 'step.dart';

/// Represents a Background block in a Gherkin feature file.
///
/// Background steps run before every scenario in the feature.
///
/// ```gherkin
/// Feature: Counter
///   Background: Setup
///     Given I have a counter with value 0
/// ```
class Background {
  /// A description of the background (text after `Background:`).
  String description;

  /// The steps that make up the background setup.
  List<Step> steps;

  Background({required this.description, required this.steps});
}
