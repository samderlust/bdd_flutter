/// Why a feature step has no method to call.
enum UnresolvedReason {
  /// No step definition matches the step's text.
  undefined,

  /// Several step definitions match it.
  ambiguous,

  /// Only the shared steps mixin matches it, and the feature's steps class
  /// does not mix it in.
  missingSharedMixin,
}
