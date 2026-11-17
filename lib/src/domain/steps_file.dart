import 'steps_class.dart';
import 'steps_problem.dart';

/// What a steps file declares, read without running it.
class StepsFile {
  /// The file path.
  final String path;

  /// Its classes and mixins, in file order.
  final List<StepsClass> classes;

  /// Annotations that could not be read, and syntax errors.
  final List<StepsProblem> problems;

  const StepsFile({required this.path, this.classes = const [], this.problems = const []});

  /// The class or mixin called [name], if any.
  StepsClass? classNamed(String name) {
    for (final stepsClass in classes) {
      if (stepsClass.name == name) return stepsClass;
    }
    return null;
  }
}
