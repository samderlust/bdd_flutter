/// The role a step plays in a scenario, independent of spoken language.
///
/// Mirrors Cucumber's `StepKeywordType`, so `Given`, `Soit` and `Angenommen`
/// all map to [context].
enum StepKeywordType {
  /// `Given` and its translations: sets up state.
  context,

  /// `When` and its translations: performs an action.
  action,

  /// `Then` and its translations: checks an outcome.
  outcome,

  /// `And`, `But` and `*`: continues the previous step.
  conjunction,

  /// Built by hand without a known keyword type.
  unknown,
}
