import '../../domain/step.dart';
import '../../domain/value_type.dart';

/// How a generated test calls a feature's steps on its `steps` object.
abstract interface class StepCalls {
  /// Imports the test file needs besides `flutter_test` and the steps file.
  List<String> get imports;

  /// Statements run right after `steps` is created, e.g. hooks.
  List<String> get setUpStatements;

  /// The statement running [step], e.g. `await steps.iAdd(2, 'apple');`.
  ///
  /// Inside a Scenario Outline, [row] holds the Examples row's values and
  /// [columns] the type of each column.
  String statementFor(Step step, {Map<String, String> row, Map<String, ValueType> columns});
}
