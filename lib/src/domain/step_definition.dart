import 'source_location.dart';
import 'step_method.dart';

/// A step method declared with `@Step`, `@Given`, `@When` or `@Then`.
class StepDefinition {
  /// The Cucumber Expression from the annotation.
  final String expression;

  /// The class or mixin that declares the method, e.g. `CartSteps`.
  final String ownerName;

  /// The method name.
  final String methodName;

  /// The method's parameters as declared, in order.
  final List<StepParameter> parameters;

  /// Where the annotation is.
  final SourceLocation location;

  const StepDefinition({
    required this.expression,
    required this.ownerName,
    required this.methodName,
    required this.parameters,
    required this.location,
  });

  @override
  String toString() => "$ownerName.$methodName ('$expression') at $location";
}
