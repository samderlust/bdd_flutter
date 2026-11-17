import 'step.dart';

/// Alias of [Step] for steps that read as `When`.
///
/// Matching ignores the keyword: a `@When` method also matches steps written
/// with another keyword.
class When extends Step {
  /// Marks a method as the code for steps matching [expression].
  const When(super.expression);
}
