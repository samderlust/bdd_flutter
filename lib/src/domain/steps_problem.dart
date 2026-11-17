import 'source_location.dart';

/// Something wrong in a steps file that `build` reports to the user, such as
/// an expression that is not a string literal or an unknown parameter type.
class StepsProblem {
  /// Where the problem is.
  final SourceLocation location;

  /// What is wrong, as shown to the user.
  final String message;

  const StepsProblem(this.location, this.message);

  @override
  String toString() => '$location: $message';
}
