/// What `StepsSourceRewriter` changed in one steps file.
class RewriteResult {
  /// The new source; the old one when [ownerFound] is false.
  final String source;

  /// Methods that received step annotations.
  final List<String> annotated;

  /// Whether the file declares the class or mixin to rewrite.
  final bool ownerFound;

  const RewriteResult(this.source, this.annotated, {this.ownerFound = true});
}
