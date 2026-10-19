/// Thrown when a `.feature` file is not valid Gherkin.
class FeatureParseException implements Exception {
  /// The `.feature` file that failed to parse.
  final String path;

  /// One message per parse error, prefixed with `(line:column)`.
  final List<String> errors;

  const FeatureParseException(this.path, this.errors);

  @override
  String toString() => 'Invalid Gherkin in $path:\n${errors.map((e) => '  $e').join('\n')}';
}
