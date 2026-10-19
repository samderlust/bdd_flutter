import '../../infrastructure/steps/steps_catalog.dart';

final RegExp _method = RegExp(r'Future<void>\s+([A-Za-z_]\w*)\s*\(');
final RegExp _overriddenMethod = RegExp(r'@override\s+Future<void>\s+([A-Za-z_]\w*)\s*\(');

/// Compares a user's steps file [source] with the steps the feature needs.
///
/// Returns one message per problem: a step method the file lacks, or an
/// `@override` method that no step uses any more. The analyzer reports the
/// same problems; this makes them visible right after `build`.
List<String> checkStepsFile(String source, String path, StepsCatalog catalog) {
  final needed = catalog.methods.map((m) => m.name).toSet();
  final defined = _method.allMatches(source).map((m) => m.group(1)!).toSet();
  final overridden = _overriddenMethod.allMatches(source).map((m) => m.group(1)!).toSet();
  final missing = needed.difference(defined).toList()..sort();
  final unused = overridden.difference(needed).toList()..sort();
  return [
    if (missing.isNotEmpty) '$path is missing ${missing.join(', ')}.',
    if (unused.isNotEmpty) '$path has steps no longer in the feature: ${unused.join(', ')}.',
  ];
}
