import 'step.dart';
import 'step_definition.dart';
import 'step_keyword_type.dart';
import 'unresolved_reason.dart';

/// A feature step that a generated test cannot call, and why.
class UnresolvedStep {
  /// The step as written in the feature.
  final Step step;

  /// The text that was matched: the step's text, with an Examples row's
  /// values filled in inside a Scenario Outline.
  final String text;

  /// Why it cannot be called.
  final UnresolvedReason reason;

  /// The matching definitions when [reason] is ambiguous or a missing mixin.
  final List<StepDefinition> candidates;

  /// The step's role: for `And`, `But` and `*`, the role of the step they
  /// continue.
  final StepKeywordType keywordType;

  const UnresolvedStep({
    required this.step,
    required this.text,
    required this.reason,
    this.candidates = const [],
    this.keywordType = StepKeywordType.unknown,
  });
}
