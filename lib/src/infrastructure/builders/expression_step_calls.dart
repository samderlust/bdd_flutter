import '../../domain/hook_kind.dart';
import '../../domain/parameter_type_definition.dart';
import '../../domain/step_definition.dart';
import '../../domain/step.dart';
import '../../domain/step_match.dart';
import '../../domain/step_match_result.dart';
import '../../domain/steps_class.dart';
import '../../domain/steps_problem.dart';
import '../../domain/unresolved_reason.dart';
import '../../domain/unresolved_step.dart';
import '../../domain/value_type.dart';
import '../../extensions/string_x.dart';
import '../steps/step_matcher.dart';
import 'argument_code.dart';
import 'row_values.dart';
import 'step_calls.dart';

/// 3.0 step calls: each step calls the method whose Cucumber Expression
/// matches its text, in the feature's steps class or the shared steps mixin.
///
/// A step that cannot be called becomes a `fail(...)` statement, so the test
/// file still compiles and the test reports the problem; [unresolved] lists
/// those steps for `build` to report.
class ExpressionStepCalls implements StepCalls {
  final String _stepsClassName;
  final StepsClass? _own;
  final StepsClass? _shared;
  final String? _sharedImport;
  final StepMatcher _matcher;
  final Map<String, ParameterTypeDefinition> _types;
  final List<UnresolvedStep> _unresolved = [];
  final Set<StepDefinition> _used = {};
  final Set<String> _warnings = {};
  bool _usesSharedStatics = false;

  /// Calls on [own], the feature's steps class [stepsClassName] (null when
  /// its file does not declare it yet), and [shared], the shared steps mixin
  /// imported in the test file as [sharedImport].
  ExpressionStepCalls({
    required String stepsClassName,
    required StepsClass? own,
    StepsClass? shared,
    String? sharedImport,
  }) : _stepsClassName = stepsClassName,
       _own = own,
       _shared = shared,
       _sharedImport = sharedImport,
       _matcher = StepMatcher.build(own: own, shared: [?shared]),
       _types = {
         for (final type in [...?own?.parameterTypes, ...?shared?.parameterTypes]) type.name: type,
       };

  /// Expressions and parameter types that could not be compiled.
  List<StepsProblem> get problems => _matcher.problems;

  /// Steps the generated tests cannot call, once per text and reason.
  List<UnresolvedStep> get unresolved => List.unmodifiable(_unresolved);

  /// The definitions a step matched (called, or reported as ambiguous or
  /// needing the mixin), plus those with an invalid expression, which are
  /// reported already. The others are unused.
  Set<StepDefinition> get usedDefinitions => Set.unmodifiable({..._used, ..._matcher.invalidDefinitions});

  /// Calls whose arguments do not fit the method, e.g. a wrong parameter
  /// count; the generated test will not compile until they are fixed.
  List<String> get warnings => _warnings.toList();

  bool get _mixesInShared => _shared != null && (_own?.mixins.contains(_shared.name) ?? false);

  @override
  List<String> get imports => [if (_usesSharedStatics && _sharedImport != null) _sharedImport];

  @override
  List<String> get setUpStatements {
    final classes = [if (_mixesInShared) _shared!, ?_own];
    final hooks = classes.expand((c) => c.hooks);
    return [
      for (final hook in hooks.where((h) => h.kind == HookKind.after)) 'addTearDown(steps.${hook.methodName});',
      for (final hook in hooks.where((h) => h.kind == HookKind.before)) 'await steps.${hook.methodName}();',
    ];
  }

  @override
  String statementFor(Step step, {Map<String, String> row = const {}, Map<String, ValueType> columns = const {}}) {
    final values = RowValues(row);
    final text = values.fill(step.text);
    final result = _matcher.match(text);
    final reason = _reasonFor(result);
    if (reason != null) return _fail(step, text, reason, result);
    final match = result.single!;
    final arguments = _arguments(match, step, values);
    _used.add(match.definition);
    _checkArity(match.definition, arguments.length, step);
    return 'await steps.${match.definition.methodName}(${arguments.join(', ')});';
  }

  void _checkArity(StepDefinition definition, int given, Step step) {
    final positional = definition.parameters.where((p) => !p.isNamed);
    final required = positional.where((p) => !p.isOptional).length;
    if (given >= required && given <= positional.length) return;
    final expected = required == positional.length ? '$required' : '$required to ${positional.length}';
    _warnings.add(
      '${definition.ownerName}.${definition.methodName} (${definition.location}) takes $expected '
      "parameter(s) but `${step.keyword} ${step.text}` passes $given: one per {parameter} in '${definition.expression}'"
      '${step.docString != null ? ', plus the doc string' : ''}${step.dataTable != null ? ', plus the data table' : ''}.',
    );
  }

  UnresolvedReason? _reasonFor(StepMatchResult result) {
    if (result.isUndefined) return UnresolvedReason.undefined;
    if (result.isAmbiguous) return UnresolvedReason.ambiguous;
    final fromShared = result.single!.definition.ownerName != _stepsClassName;
    return fromShared && !_mixesInShared ? UnresolvedReason.missingSharedMixin : null;
  }

  List<String> _arguments(StepMatch match, Step step, RowValues values) {
    final docString = step.docString;
    final dataTable = step.dataTable;
    return [
      for (final argument in match.arguments) argumentCode(argument, customType: _customType(argument.typeName)),
      if (docString != null) values.docStringLiteral(docString),
      if (dataTable != null) values.dataTableLiteral(dataTable),
    ];
  }

  ParameterTypeDefinition? _customType(String name) {
    final type = _types[name];
    if (type != null && type.ownerName == _shared?.name) _usesSharedStatics = true;
    return type;
  }

  String _fail(Step step, String text, UnresolvedReason reason, StepMatchResult result) {
    final candidates = result.matches.map((m) => m.definition).toList();
    _used.addAll(candidates);
    final known = _unresolved.any((u) => u.text == text && u.reason == reason);
    if (!known) _unresolved.add(UnresolvedStep(step: step, text: text, reason: reason, candidates: candidates));
    final message = switch (reason) {
      UnresolvedReason.undefined => 'Undefined step: ${step.keyword} $text',
      UnresolvedReason.ambiguous =>
        'Ambiguous step: ${step.keyword} $text matches ${candidates.map((d) => '${d.ownerName}.${d.methodName}').join(', ')}',
      UnresolvedReason.missingSharedMixin =>
        'Step ${step.keyword} $text is defined in ${_shared!.name}; add `with ${_shared.name}` to $_stepsClassName',
    };
    return 'fail(${message.toDartStringLiteral});';
  }
}
