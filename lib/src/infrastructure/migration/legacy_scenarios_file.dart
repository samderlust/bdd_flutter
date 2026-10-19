import 'dart_source_mask.dart';

/// A step method found in a 1.x scenario or background class.
class LegacyMethod {
  /// The method name.
  final String name;

  /// The parameter list as written, without parentheses.
  final String parameters;

  /// The code between the method's braces, as written.
  final String body;

  /// Whether the body has code, not just comments and whitespace.
  final bool hasCode;

  const LegacyMethod({required this.name, required this.parameters, required this.body, required this.hasCode});
}

/// A class in a 1.x `.bdd_scenarios.dart` file.
class LegacyClass {
  /// The class name, e.g. `IncrementScenario`.
  final String name;

  /// Step methods by name.
  final Map<String, LegacyMethod> methods;

  /// Every other member as written: fields, getters, helper methods.
  /// Constructors are left out.
  final List<String> otherMembers;

  const LegacyClass({required this.name, required this.methods, required this.otherMembers});
}

/// The parts of a 1.x `.bdd_scenarios.dart` file that `migrate` carries
/// over.
class LegacyScenariosFile {
  /// `import` lines.
  final List<String> imports;

  /// Top-level declarations other than imports and classes, e.g. a shared
  /// `late Cart cart;`.
  final List<String> topLevel;

  /// Classes by name.
  final Map<String, LegacyClass> classes;

  const LegacyScenariosFile({required this.imports, required this.topLevel, required this.classes});

  /// Reads [source]. Code it cannot classify ends up in [topLevel].
  factory LegacyScenariosFile.parse(String source) {
    final masked = maskDartSource(source);
    final imports = <String>[];
    final topLevel = <String>[];
    final classes = <String, LegacyClass>{};
    for (final (start, end) in _declarations(masked, 0, masked.length)) {
      final text = source.substring(start, end).trim();
      final header = masked.substring(start, end);
      if (RegExp(r'^\s*(import|export)\b').hasMatch(header)) {
        imports.add(text);
      } else if (RegExp(r'^\s*(library|part)\b').hasMatch(header)) {
        continue;
      } else {
        final legacyClass = _class(source, masked, start, end);
        legacyClass == null ? topLevel.add(text) : classes[legacyClass.name] = legacyClass;
      }
    }
    return LegacyScenariosFile(imports: imports, topLevel: topLevel, classes: classes);
  }

  static final RegExp _classHeader = RegExp(
    r'^\s*(?:(?:abstract|base|final|sealed|interface|mixin)\s+)*class\s+(\w+)[^{]*\{',
  );
  static final RegExp _methodHeader = RegExp(r'^\s*(?:@\w+\s+)*Future<void>\s+(\w+)\s*\(');

  static LegacyClass? _class(String source, String masked, int start, int end) {
    final header = _classHeader.firstMatch(masked.substring(start, end));
    if (header == null) return null;
    final name = header.group(1)!;
    final bodyStart = start + header.end;
    final bodyEnd = masked.lastIndexOf('}', end - 1);
    final methods = <String, LegacyMethod>{};
    final otherMembers = <String>[];
    for (final (s, e) in _declarations(masked, bodyStart, bodyEnd)) {
      final method = _method(source, masked, s, e);
      if (method != null) {
        methods[method.name] = method;
      } else if (!_isConstructorOrStep(masked.substring(s, e), name)) {
        otherMembers.add(source.substring(s, e).trim());
      }
    }
    return LegacyClass(name: name, methods: methods, otherMembers: otherMembers);
  }

  /// Constructors would not compile in the new class, and a step method
  /// the reader could not take apart (e.g. one with an `=>` body) would
  /// clash with the generated method of the same name.
  static bool _isConstructorOrStep(String maskedMember, String className) {
    final constructor = RegExp('^\\s*(const\\s+|factory\\s+)?$className\\s*[.(]');
    return constructor.hasMatch(maskedMember) || _methodHeader.hasMatch(maskedMember);
  }

  static LegacyMethod? _method(String source, String masked, int start, int end) {
    final chunk = masked.substring(start, end);
    final header = _methodHeader.firstMatch(chunk);
    if (header == null) return null;
    final paramsStart = start + header.end;
    final paramsEnd = _matching(masked, paramsStart - 1, '(', ')');
    final bodyStart = masked.indexOf('{', paramsEnd);
    if (bodyStart < 0 || bodyStart >= end) return null;
    final bodyEnd = _matching(masked, bodyStart, '{', '}');
    return LegacyMethod(
      name: header.group(1)!,
      parameters: source.substring(paramsStart, paramsEnd).trim(),
      body: source.substring(bodyStart + 1, bodyEnd),
      hasCode: masked.substring(bodyStart + 1, bodyEnd).trim().isNotEmpty,
    );
  }

  /// Start and end of each declaration between [from] and [to]: up to a
  /// `;` at the outer level, or a closing `}` not followed by `;`, `,` or
  /// `)`.
  static Iterable<(int, int)> _declarations(String masked, int from, int to) sync* {
    var i = from;
    while (true) {
      while (i < to && masked[i].trim().isEmpty) {
        i++;
      }
      if (i >= to) return;
      final start = i;
      i = _declarationEnd(masked, i, to);
      yield (start, i);
    }
  }

  static int _declarationEnd(String masked, int start, int to) {
    var parens = 0;
    for (var i = start; i < to; i++) {
      final char = masked[i];
      if (char == '(' || char == '[') parens++;
      if (char == ')' || char == ']') parens--;
      if (char == ';' && parens == 0) return i + 1;
      if (char == '{' && parens == 0) {
        i = _matching(masked, i, '{', '}');
        final next = masked.substring(i + 1, to).trimLeft();
        if (next.isEmpty || !RegExp(r'^[;,)]').hasMatch(next)) return i + 1;
      }
    }
    return to;
  }

  /// Index of the [close] that matches the [open] at [index].
  static int _matching(String masked, int index, String open, String close) {
    var depth = 0;
    for (var i = index; i < masked.length; i++) {
      if (masked[i] == open) depth++;
      if (masked[i] == close && --depth == 0) return i;
    }
    return masked.length - 1;
  }
}
