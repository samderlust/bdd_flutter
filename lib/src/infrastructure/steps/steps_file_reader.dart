import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';

import '../../domain/hook_definition.dart';
import '../../domain/hook_kind.dart';
import '../../domain/parameter_type_definition.dart';
import '../../domain/source_location.dart';
import '../../domain/step_definition.dart';
import '../../domain/step_method.dart';
import '../../domain/steps_class.dart';
import '../../domain/steps_file.dart';
import '../../domain/steps_problem.dart';

/// Reads the step definitions, parameter types and hooks of a steps file
/// from its source, without resolving or running it.
///
/// Annotations are recognised by name (`@Step`, `@Given`, `@When`, `@Then`,
/// `@ParameterType`, `@Before`, `@After`, optionally with an import prefix).
/// Their expressions and regexes must be string literals.
class StepsFileReader {
  const StepsFileReader();

  static const Set<String> _stepAnnotations = {'Step', 'Given', 'When', 'Then'};

  /// Reads the file at [path]; a missing file reads as empty.
  StepsFile read(String path) {
    final file = File(path);
    if (!file.existsSync()) return StepsFile(path: path);
    return parse(file.readAsStringSync(), path: path);
  }

  /// Reads [content] as if it were the file at [path].
  StepsFile parse(String content, {required String path}) {
    final result = parseString(content: content, path: path, throwIfDiagnostics: false);
    final context = _ReadContext(path, result.lineInfo);
    for (final diagnostic in result.errors) {
      context.problem(diagnostic.offset, 'Syntax error: ${diagnostic.message}');
    }
    final classes = <StepsClass>[
      for (final declaration in result.unit.declarations)
        if (_readDeclaration(declaration, context) case final StepsClass stepsClass) stepsClass,
    ];
    return StepsFile(path: path, classes: classes, problems: context.problems);
  }

  StepsClass? _readDeclaration(CompilationUnitMember declaration, _ReadContext context) {
    return switch (declaration) {
      ClassDeclaration() => _readClass(declaration.namePart.typeName.lexeme, declaration.body, false, context),
      MixinDeclaration() => _readClass(declaration.name.lexeme, declaration.body, true, context),
      _ => null,
    };
  }

  StepsClass _readClass(String name, ClassBody body, bool isMixin, _ReadContext context) {
    final owner = _OwnerBuilder(name);
    for (final method in body.members.whereType<MethodDeclaration>()) {
      for (final annotation in method.metadata) {
        _readAnnotation(annotation, method, owner, context);
      }
    }
    return StepsClass(
      name: name,
      path: context.path,
      isMixin: isMixin,
      steps: owner.steps,
      parameterTypes: owner.parameterTypes,
      hooks: owner.hooks,
    );
  }

  void _readAnnotation(Annotation annotation, MethodDeclaration method, _OwnerBuilder owner, _ReadContext context) {
    final name = _annotationName(annotation);
    if (_stepAnnotations.contains(name)) {
      _readStep(annotation, method, owner, context);
    } else if (name == 'ParameterType') {
      _readParameterType(annotation, method, owner, context);
    } else if (name == 'Before' || name == 'After') {
      _readHook(name == 'Before' ? HookKind.before : HookKind.after, annotation, method, owner, context);
    }
  }

  void _readStep(Annotation annotation, MethodDeclaration method, _OwnerBuilder owner, _ReadContext context) {
    final expression = _positionalString(annotation);
    if (expression == null) {
      context.problem(annotation.offset, '@${_annotationName(annotation)} needs one string literal expression.');
      return;
    }
    owner.steps.add(
      StepDefinition(
        expression: expression,
        ownerName: owner.name,
        methodName: method.name.lexeme,
        parameters: _parameters(method),
        location: context.locationOf(annotation.offset),
      ),
    );
  }

  void _readParameterType(Annotation annotation, MethodDeclaration method, _OwnerBuilder owner, _ReadContext context) {
    final regex = _positionalString(annotation);
    final problem = _parameterTypeProblem(annotation, method, regex);
    if (problem != null) {
      context.problem(annotation.offset, problem);
      return;
    }
    owner.parameterTypes.add(
      ParameterTypeDefinition(
        name: _namedString(annotation, 'name') ?? method.name.lexeme,
        regex: regex!,
        ownerName: owner.name,
        methodName: method.name.lexeme,
        dartType: method.returnType?.toSource() ?? 'dynamic',
        location: context.locationOf(annotation.offset),
      ),
    );
  }

  String? _parameterTypeProblem(Annotation annotation, MethodDeclaration method, String? regex) {
    if (regex == null) return '@ParameterType needs one string literal regex.';
    if (_hasNamedArgument(annotation, 'name') && _namedString(annotation, 'name') == null) {
      return '@ParameterType name must be a string literal.';
    }
    if (!method.isStatic) return '@ParameterType method ${method.name.lexeme} must be static.';
    final parameters = _parameters(method);
    if (parameters.length != 1 || parameters.single.dartType != 'String') {
      return '@ParameterType method ${method.name.lexeme} must take a single String.';
    }
    return null;
  }

  void _readHook(
    HookKind kind,
    Annotation annotation,
    MethodDeclaration method,
    _OwnerBuilder owner,
    _ReadContext context,
  ) {
    if (method.isStatic || _hasRequiredParameter(method)) {
      context.problem(annotation.offset, 'Hook ${method.name.lexeme} must be an instance method without arguments.');
      return;
    }
    owner.hooks.add(
      HookDefinition(
        kind: kind,
        ownerName: owner.name,
        methodName: method.name.lexeme,
        location: context.locationOf(annotation.offset),
      ),
    );
  }

  static String _annotationName(Annotation annotation) {
    final name = annotation.name;
    return name is PrefixedIdentifier ? name.identifier.name : name.name;
  }

  static String? _positionalString(Annotation annotation) {
    final positional = annotation.arguments?.arguments.where((a) => a is! NamedArgument).toList() ?? const [];
    if (positional.length != 1) return null;
    return _literal(positional.single.argumentExpression);
  }

  static NamedArgument? _named(Annotation annotation, String name) {
    for (final argument in annotation.arguments?.arguments ?? const <Argument>[]) {
      if (argument is NamedArgument && argument.name.lexeme == name) return argument;
    }
    return null;
  }

  static bool _hasNamedArgument(Annotation annotation, String name) => _named(annotation, name) != null;

  static String? _namedString(Annotation annotation, String name) {
    final argument = _named(annotation, name);
    return argument == null ? null : _literal(argument.argumentExpression);
  }

  /// The value of a string literal without interpolation, otherwise null.
  static String? _literal(Expression expression) => expression is StringLiteral ? expression.stringValue : null;

  static List<StepParameter> _parameters(MethodDeclaration method) {
    return [
      for (final parameter in method.parameters?.parameters ?? const <FormalParameter>[])
        StepParameter(parameter.type?.toSource() ?? 'dynamic', parameter.name?.lexeme ?? ''),
    ];
  }

  static bool _hasRequiredParameter(MethodDeclaration method) {
    return method.parameters?.parameters.any((p) => p.isRequired) ?? false;
  }
}

/// The definitions collected for one class or mixin.
class _OwnerBuilder {
  final String name;
  final List<StepDefinition> steps = [];
  final List<ParameterTypeDefinition> parameterTypes = [];
  final List<HookDefinition> hooks = [];

  _OwnerBuilder(this.name);
}

/// The file being read: its path, line numbers and problems found so far.
class _ReadContext {
  final String path;
  final LineInfo lineInfo;
  final List<StepsProblem> problems = [];

  _ReadContext(this.path, this.lineInfo);

  SourceLocation locationOf(int offset) => SourceLocation(path, lineInfo.getLocation(offset).lineNumber);

  void problem(int offset, String message) => problems.add(StepsProblem(locationOf(offset), message));
}
