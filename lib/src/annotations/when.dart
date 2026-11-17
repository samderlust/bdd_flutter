import 'step_definition.dart';

/// Alias of [StepDefinition] for steps that read as `When`.
///
/// Matching ignores the keyword: a `@When` method also matches steps written
/// with another keyword.
class When extends StepDefinition {
  /// Marks a method as the code for steps matching [expression].
  const When(super.expression);
}
