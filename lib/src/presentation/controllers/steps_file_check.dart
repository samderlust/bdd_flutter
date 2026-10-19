final RegExp _method = RegExp(r'Future<void>\s+([A-Za-z_]\w*)\s*\(');
final RegExp _overriddenMethod = RegExp(r'@override\s+Future<void>\s+([A-Za-z_]\w*)\s*\(');

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
  final overridden = _overriddenMethod.allMatches(source).map((m) => m.group(1)!).toSet();
  final missing = needed.difference(defined).toList()..sort();
  final unused = overridden.difference({...needed, ...provided}).toList()..sort();
  return [
    if (missing.isNotEmpty) '$path is missing ${missing.join(', ')}.',
    if (unused.isNotEmpty) '$path has steps no longer in any feature: ${unused.join(', ')}.',
  ];
}
