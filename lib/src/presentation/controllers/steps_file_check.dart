final RegExp _method = RegExp(r'Future<void>\s+([A-Za-z_]\w*)\s*\(');
final RegExp _overriddenMethod = RegExp(r'@override\s+Future<void>\s+([A-Za-z_]\w*)\s*\(');

/// The names of the step methods (`Future<void> name(`) in [source].
Set<String> definedMethods(String source) {
  return _method.allMatches(source).map((m) => m.group(1)!).toSet();
}

/// The parameter types of each step method in [source], by method name:
/// `Future<void> iAdd(num quantity, String item)` gives `iAdd: [num, String]`.
Map<String, List<String>> definedSignatures(String source) {
  return {for (final match in _method.allMatches(source)) match.group(1)!: _parameterTypes(source, match.end)};
}

/// The types in the parameter list that starts at [start], just after `(`.
List<String> _parameterTypes(String source, int start) {
  final parameters = <String>[];
  var depth = 0;
  var current = StringBuffer();
  for (var i = start; i < source.length; i++) {
    final char = source[i];
    if (depth == 0 && (char == ')' || char == ',')) {
      if (current.toString().trim().isNotEmpty) parameters.add(current.toString());
      if (char == ')') break;
      current = StringBuffer();
      continue;
    }
    if (char == '<' || char == '(') depth++;
    if (char == '>' || char == ')') depth--;
    current.write(char);
  }
  return parameters.map(_typeOf).toList();
}

/// `num quantity` → `num`; `final List<List<String>> table` →
/// `List<List<String>>`.
String _typeOf(String parameter) {
  final words = parameter.trim().replaceFirst(RegExp(r'^final\s+'), '').split(RegExp(r'\s+'));
  return words.take(words.length - 1).join(' ').replaceAll(' ', '');
}

/// The names of the `@override` step methods in [source].
Set<String> overriddenMethods(String source) {
  return _overriddenMethod.allMatches(source).map((m) => m.group(1)!).toSet();
}

/// Compares a user's steps file [source] with the step methods it should
/// define.
///
/// [needed] must be defined in the file; [provided] may be, e.g. steps the
/// shared mixin already supplies. Returns one message per problem: a needed
/// method the file lacks, or an `@override` method that is neither needed
/// nor provided. The analyzer reports the same problems; this makes them
/// visible right after `build`.
List<String> checkStepsFile(
  String source,
  String path, {
  required Set<String> needed,
  Set<String> provided = const {},
}) {
  final defined = _method.allMatches(source).map((m) => m.group(1)!).toSet();
  final overridden = overriddenMethods(source);
  final missing = needed.difference(defined).toList()..sort();
  final unused = overridden.difference({...needed, ...provided}).toList()..sort();
  return [
    if (missing.isNotEmpty) '$path is missing ${missing.join(', ')}.',
    if (unused.isNotEmpty) '$path has steps no longer in any feature: ${unused.join(', ')}.',
  ];
}
