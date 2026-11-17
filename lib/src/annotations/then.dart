import 'step_definition.dart';

/// Alias of [StepDefinition] for steps that read as `Then`.
///
/// Matching ignores the keyword: a `@Then` method also matches steps written
/// with another keyword.
class Then extends StepDefinition {
  /// Marks a method as the code for steps matching [expression].
  const Then(super.expression);
}
