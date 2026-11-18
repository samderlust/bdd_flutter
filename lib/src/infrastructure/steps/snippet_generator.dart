import 'package:cucumber_expressions/cucumber_expressions.dart' as ce;

import '../../domain/parameter_type_definition.dart';
import '../../domain/step_keyword_type.dart';
import '../../domain/step_method.dart';
import '../../domain/step_snippet.dart';
import '../../domain/unresolved_step.dart';
import '../../extensions/string_x.dart';
import 'parameter_names.dart';
import 'step_type_registry.dart';

/// Suggests a step definition for an undefined step, as Cucumber does:
/// `CucumberExpressionGenerator` turns numbers and quoted text into
/// `{int}`, `{float}` and `{string}`, and text matching a user's
/// `@ParameterType` into that type.
class SnippetGenerator {
  final ce.CucumberExpressionGenerator _generator;
  final Map<String, String> _customDartTypes;

  SnippetGenerator._(this._generator, this._customDartTypes);

  static const Map<String, String> _builtInDartTypes = {'int': 'int', 'float': 'double', 'string': 'String'};
  static const Map<String, String> _builtInNames = {'int': 'number', 'float': 'value', 'string': 'text'};

  /// A generator that can use the built-in types and [types].
  factory SnippetGenerator.build(Iterable<ParameterTypeDefinition> types) {
    final registry = StepTypeRegistry.build(types);
    return SnippetGenerator._(ce.CucumberExpressionGenerator(registry.registry), {
      for (final type in types) type.name: type.dartType,
    });
  }

  /// The snippet for [step].
  StepSnippet snippetFor(UnresolvedStep step) {
    final generated = _generator.generateExpressions(step.text).first;
    final usedNames = <String>{};
    final typeNames = [for (final type in generated.parameterTypes) type.name ?? ''];
    final contextNames = parameterNamesFrom(generated.source, typeNames);
    return StepSnippet(
      annotation: _annotation(step.keywordType),
      expression: generated.source,
      methodName: _methodName(generated.source, step.text),
      parameters: [
        for (var i = 0; i < typeNames.length; i++) _parameter(typeNames[i], contextNames[i], usedNames),
        if (step.step.docString != null) StepParameter('String', _unique('docString', usedNames)),
        if (step.step.dataTable != null) StepParameter('List<List<String>>', _unique('dataTable', usedNames)),
      ],
    );
  }

  /// A parameter of type [typeName]: a custom type is named after the type,
  /// a built-in one after its [contextName] when there is one.
  StepParameter _parameter(String typeName, String? contextName, Set<String> usedNames) {
    final dartType = _builtInDartTypes[typeName] ?? _customDartTypes[typeName] ?? 'String';
    final builtInName = _builtInNames[typeName];
    final name = builtInName == null
        ? typeName.toCamelIdentifier(prefix: 'value') ?? 'value'
        : contextName ?? builtInName;
    return StepParameter(dartType, _unique(name, usedNames));
  }

  /// The words of [expression] without its parameters, e.g.
  /// `I add {int} {string}` → `iAdd`.
  static String _methodName(String expression, String text) {
    final words = expression.replaceAll(RegExp(r'(?<!\\)\{[^}]*\}'), ' ').replaceAll(r'\', '');
    return words.toCamelIdentifier() ?? 'step${text.shortHash}';
  }

  static String _annotation(StepKeywordType type) {
    return switch (type) {
      StepKeywordType.context => 'Given',
      StepKeywordType.action => 'When',
      StepKeywordType.outcome => 'Then',
      _ => 'StepDefinition',
    };
  }

  static String _unique(String name, Set<String> used) {
    var candidate = name;
    for (var i = 2; !used.add(candidate); i++) {
      candidate = '$name$i';
    }
    return candidate;
  }
}
