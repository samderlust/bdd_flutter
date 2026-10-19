/// One parameter of a generated step method.
class StepParameter {
  /// The Dart type, e.g. `num` or `List<List<String>>`.
  final String dartType;

  /// The parameter name.
  final String name;

  const StepParameter(this.dartType, this.name);

  /// The declaration as written in Dart, e.g. `num quantity`.
  String get declaration => '$dartType $name';
}

/// A method of a feature's steps class, shared by every step with the same
/// pattern.
class StepMethod {
  /// The method name.
  final String name;

  /// The parameters, in call order: slots, then doc string, then data table.
  final List<StepParameter> parameters;

  /// Every distinct step (keyword and text) that calls this method, in
  /// file order; shown in the method's doc comment.
  final List<String> stepMessages;

  const StepMethod({required this.name, required this.parameters, required this.stepMessages});

  /// The method signature without a body, e.g.
  /// `Future<void> iAddAtEach(num quantity, String item)`.
  String get signature => 'Future<void> $name(${parameters.map((p) => p.declaration).join(', ')})';
}
