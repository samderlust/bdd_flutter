/// A line in a source file, used to point at definitions and problems.
class SourceLocation {
  /// The file path as given to the reader.
  final String path;

  /// The 1-based line number.
  final int line;

  const SourceLocation(this.path, this.line);

  @override
  String toString() => '$path:$line';
}
