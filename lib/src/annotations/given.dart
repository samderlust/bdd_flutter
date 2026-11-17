import 'step_definition.dart';

/// Alias of [StepDefinition] for steps that read as `Given`.
///
/// Matching ignores the keyword: a `@Given` method also matches steps written
/// with another keyword.
class Given extends StepDefinition {
  /// Marks a method as the code for steps matching [expression].
  const Given(super.expression);
}
