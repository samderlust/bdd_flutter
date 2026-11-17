import 'step.dart';

/// Alias of [Step] for steps that read as `Given`.
///
/// Matching ignores the keyword: a `@Given` method also matches steps written
/// with another keyword.
class Given extends Step {
  /// Marks a method as the code for steps matching [expression].
  const Given(super.expression);
}
