import 'matched_argument.dart';
import 'step_definition.dart';

/// A step definition whose expression matches a step's text, with the
/// values taken from that text.
class StepMatch {
  /// The matching definition.
  final StepDefinition definition;

  /// One argument per parameter in the expression, in order.
  final List<MatchedArgument> arguments;

  const StepMatch(this.definition, this.arguments);
}
