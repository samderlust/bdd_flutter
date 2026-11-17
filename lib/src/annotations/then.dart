import 'step.dart';

/// Alias of [Step] for steps that read as `Then`.
///
/// Matching ignores the keyword: a `@Then` method also matches steps written
/// with another keyword.
class Then extends Step {
  /// Marks a method as the code for steps matching [expression].
  const Then(super.expression);
}
