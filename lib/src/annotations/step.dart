/// Marks a method of a steps class as the code for every feature step whose
/// text matches [expression].
///
/// [expression] is a
/// [Cucumber Expression](https://github.com/cucumber/cucumber-expressions#readme):
///
/// ```dart
/// @Step('I have {int} cucumber(s) in my belly/stomach')
/// Future<void> iHaveCucumbers(int count) async { ... }
/// ```
///
/// The step keyword (Given, When, Then, And, But) is ignored when matching,
/// so [Given], [When] and [Then] are only aliases that read better.
///
/// The expression must be a string literal: `build` reads it from the source
/// without running your code.
class Step {
  /// The Cucumber Expression the step text must match.
  final String expression;

  /// Marks a method as the code for steps matching [expression].
  const Step(this.expression);
}
