import '../../domain/feature.dart';
import '../../domain/step.dart';
import '../../domain/value_type.dart';
import '../steps/steps_catalog.dart';
import 'step_arguments.dart';
import 'step_calls.dart';

/// 2.x step calls: each step calls the contract method of its pattern.
class CatalogStepCalls implements StepCalls {
  final Feature _feature;
  final StepsCatalog _catalog;

  const CatalogStepCalls(this._feature, this._catalog);

  @override
  List<String> get imports => const [];

  @override
  List<String> get setUpStatements => const [];

  @override
  String statementFor(Step step, {Map<String, String> row = const {}, Map<String, ValueType> columns = const {}}) {
    final pattern = _catalog.patternOf(step, columns: columns);
    final method = _catalog.methodOf(_feature, pattern);
    return 'await steps.${method.name}(${stepArguments(step, pattern, row: row).join(', ')});';
  }
}
