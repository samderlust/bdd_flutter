import 'hook_kind.dart';
import 'source_location.dart';

/// A scenario hook declared with `@Before` or `@After`.
class HookDefinition {
  /// When the hook runs.
  final HookKind kind;

  /// The class or mixin that declares the method.
  final String ownerName;

  /// The method name.
  final String methodName;

  /// Where the annotation is.
  final SourceLocation location;

  const HookDefinition({required this.kind, required this.ownerName, required this.methodName, required this.location});
}
