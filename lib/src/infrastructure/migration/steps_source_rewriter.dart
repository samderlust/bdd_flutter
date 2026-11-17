import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'rewrite_result.dart';

/// Rewrites a 2.x steps file for Cucumber Expressions, editing only what
/// must change so the user's code and formatting stay as they are:
///
/// - adds a step annotation such as `@When('...')` to every step method of
///   the class or mixin;
/// - removes `@override` from those methods and from the `tester` field;
/// - removes `implements <Feature>StepsContract` and the contract's import;
/// - adds `import 'package:bdd_flutter/bdd_flutter.dart';`, and hides the
///   names it would clash with in other imports, e.g. mocktail's `When`.
///
/// Methods that already have a step annotation are left alone, so running
/// it twice changes nothing.
class StepsSourceRewriter {
  const StepsSourceRewriter();

  static const Set<String> _stepAnnotations = {'StepDefinition', 'Given', 'When', 'Then'};
  static const String _packageImport = "import 'package:bdd_flutter/bdd_flutter.dart';";

  /// Libraries that export a name bdd_flutter's annotations also use.
  static const Map<String, List<String>> clashingNames = {
    'package:mocktail/mocktail.dart': ['When'],
  };

  /// Rewrites [ownerName] in [source]: each method named in [annotations]
  /// gets those annotations, written as source such as
  /// `@When('I add {num}')`. [contractClass] and
  /// [contractFileName] name the 2.x contract to drop. With
  /// [keepTesterOverride], `@override` stays on `tester` (it overrides the
  /// shared mixin's getter).
  RewriteResult rewrite(
    String source, {
    required String ownerName,
    required Map<String, List<String>> annotations,
    String? contractClass,
    String? contractFileName,
    bool keepTesterOverride = false,
  }) {
    final unit = parseString(content: source, throwIfDiagnostics: false).unit;
    final edits = <_Edit>[];
    final annotated = <String>[];
    var found = false;
    for (final declaration in unit.declarations) {
      final (name, body) = switch (declaration) {
        ClassDeclaration() => (declaration.namePart.typeName.lexeme, declaration.body),
        MixinDeclaration() => (declaration.name.lexeme, declaration.body),
        _ => (null, null),
      };
      if (name != ownerName || body == null) continue;
      found = true;
      if (declaration is ClassDeclaration) _dropImplements(declaration, contractClass, edits);
      annotated.addAll(_annotateMethods(body, annotations, source, edits));
      if (!keepTesterOverride) _dropTesterOverride(body, source, edits);
    }
    if (!found) return RewriteResult(source, const [], ownerFound: false);
    _dropContractImport(unit, contractFileName, source, edits);
    if (annotated.isNotEmpty) {
      _addPackageImport(unit, source, edits);
      _hideClashes(unit, edits);
    }
    return RewriteResult(_apply(source, edits), annotated);
  }

  void _dropContractImport(CompilationUnit unit, String? fileName, String source, List<_Edit> edits) {
    if (fileName == null) return;
    for (final directive in unit.directives.whereType<ImportDirective>()) {
      if (directive.uri.stringValue == fileName) edits.add(_Edit.removeLine(source, directive.offset, directive.end));
    }
  }

  void _addPackageImport(CompilationUnit unit, String source, List<_Edit> edits) {
    final imports = unit.directives.whereType<ImportDirective>();
    if (imports.any((d) => d.uri.stringValue == 'package:bdd_flutter/bdd_flutter.dart')) return;
    final offset = imports.isEmpty ? 0 : imports.first.offset;
    edits.add(_Edit(offset, 0, imports.isEmpty ? '$_packageImport\n\n' : '$_packageImport\n'));
  }

  /// Hides [clashingNames] in imports that would expose them: adds them to
  /// an existing `hide`, or a new one. Prefixed imports, and `show` lists
  /// without those names, expose nothing and are left alone.
  void _hideClashes(CompilationUnit unit, List<_Edit> edits) {
    for (final directive in unit.directives.whereType<ImportDirective>()) {
      final names = clashingNames[directive.uri.stringValue];
      if (names == null || directive.prefix != null) continue;
      final combinators = directive.combinators;
      final shown = {for (final c in combinators.whereType<ShowCombinator>()) ...c.shownNames.map((n) => n.name)};
      final hidden = {for (final c in combinators.whereType<HideCombinator>()) ...c.hiddenNames.map((n) => n.name)};
      if (combinators.whereType<ShowCombinator>().isNotEmpty && !names.any(shown.contains)) continue;
      final missing = names.where((n) => !hidden.contains(n)).toList();
      if (missing.isEmpty) continue;
      final hide = combinators.whereType<HideCombinator>().firstOrNull;
      edits.add(
        hide == null
            ? _Edit(directive.semicolon.offset, 0, ' hide ${missing.join(', ')}')
            : _Edit(hide.end, 0, ', ${missing.join(', ')}'),
      );
    }
  }

  void _dropImplements(ClassDeclaration declaration, String? contractClass, List<_Edit> edits) {
    final clause = declaration.implementsClause;
    if (clause == null || contractClass == null) return;
    final others = clause.interfaces.where((t) => t.name.lexeme != contractClass).toList();
    if (others.length == clause.interfaces.length) return;
    if (others.isEmpty) {
      final start = clause.beginToken.previous!.end;
      edits.add(_Edit(start, clause.end - start, ''));
    } else {
      edits.add(_Edit(clause.offset, clause.length, 'implements ${others.map((t) => t.toSource()).join(', ')}'));
    }
  }

  List<String> _annotateMethods(
    ClassBody body,
    Map<String, List<String>> annotations,
    String source,
    List<_Edit> edits,
  ) {
    final annotated = <String>[];
    for (final method in body.members.whereType<MethodDeclaration>()) {
      final methodAnnotations = annotations[method.name.lexeme];
      if (methodAnnotations == null || _hasStepAnnotation(method.metadata)) continue;
      _dropOverrides(method.metadata, edits);
      final start = method.firstTokenAfterCommentAndMetadata.offset;
      final indent = _indentAt(source, start);
      edits.add(_Edit(start, 0, '${methodAnnotations.join('\n$indent')}\n$indent'));
      annotated.add(method.name.lexeme);
    }
    return annotated;
  }

  void _dropTesterOverride(ClassBody body, String source, List<_Edit> edits) {
    for (final field in body.members.whereType<FieldDeclaration>()) {
      if (field.fields.variables.any((v) => v.name.lexeme == 'tester')) _dropOverrides(field.metadata, edits);
    }
  }

  void _dropOverrides(NodeList<Annotation> metadata, List<_Edit> edits) {
    for (final annotation in metadata.where((a) => a.name.name == 'override')) {
      final next = annotation.endToken.next!.offset;
      edits.add(_Edit(annotation.offset, next - annotation.offset, ''));
    }
  }

  bool _hasStepAnnotation(NodeList<Annotation> metadata) {
    return metadata.any((a) {
      final name = a.name;
      return _stepAnnotations.contains(name is PrefixedIdentifier ? name.identifier.name : name.name);
    });
  }

  /// The spaces before [offset] on its line.
  String _indentAt(String source, int offset) {
    final lineStart = source.lastIndexOf('\n', offset - 1) + 1;
    final prefix = source.substring(lineStart, offset);
    return prefix.trim().isEmpty ? prefix : prefix.substring(0, prefix.length - prefix.trimLeft().length);
  }

  /// [edits] applied from the end, insertions before removals at the same
  /// offset, so earlier offsets stay valid.
  String _apply(String source, List<_Edit> edits) {
    final sorted = [...edits]
      ..sort((a, b) => a.offset != b.offset ? b.offset.compareTo(a.offset) : a.length.compareTo(b.length));
    var result = source;
    for (final edit in sorted) {
      result = result.replaceRange(edit.offset, edit.offset + edit.length, edit.replacement);
    }
    return result;
  }
}

/// A replacement of [length] characters at [offset].
class _Edit {
  final int offset;
  final int length;
  final String replacement;

  const _Edit(this.offset, this.length, this.replacement);

  /// Removes [start]–[end] with the line break after it.
  factory _Edit.removeLine(String source, int start, int end) {
    final stop = end < source.length && source[end] == '\n' ? end + 1 : end;
    return _Edit(start, stop - start, '');
  }
}
