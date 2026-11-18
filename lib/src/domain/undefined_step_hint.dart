/// An undefined step as `build` reports it: a warning, then where to add
/// the step definition and a snippet to paste.
class UndefinedStepHint {
  /// The one-line warning, e.g. ``undefined step `Given I am logged in` in a.feature.``
  final String warning;

  /// Lines printed under the warning: where to add it, then the snippet.
  final List<String> details;

  const UndefinedStepHint(this.warning, this.details);
}
