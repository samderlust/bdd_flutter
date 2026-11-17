import 'hook_definition.dart';
import 'parameter_type_definition.dart';
import 'step_definition.dart';

/// A class or mixin in a steps file, with what it declares for `build`.
class StepsClass {
  /// The class or mixin name.
  final String name;

  /// The file that declares it.
  final String path;

  /// Whether it is a mixin (it cannot be created on its own).
  final bool isMixin;

  /// Its step methods, one per annotation.
  final List<StepDefinition> steps;

  /// Its custom parameter types.
  final List<ParameterTypeDefinition> parameterTypes;

  /// Its scenario hooks.
  final List<HookDefinition> hooks;

  const StepsClass({
    required this.name,
    required this.path,
    this.isMixin = false,
    this.steps = const [],
    this.parameterTypes = const [],
    this.hooks = const [],
  });
}
