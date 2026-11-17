import 'step_match.dart';

/// The outcome of looking up a step's text among the step definitions.
///
/// Definitions of the feature's own class are tried first; shared classes
/// are only tried when none of them matches.
class StepMatchResult {
  /// Every match from the first group of classes that had any.
  final List<StepMatch> matches;

  const StepMatchResult(this.matches);

  /// No definition matches: `build` suggests a snippet.
  bool get isUndefined => matches.isEmpty;

  /// Several definitions match: `build` reports an error.
  bool get isAmbiguous => matches.length > 1;

  /// The single match, when there is exactly one.
  StepMatch? get single => matches.length == 1 ? matches.single : null;
}
