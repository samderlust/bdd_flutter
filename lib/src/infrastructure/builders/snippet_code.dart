import '../../domain/step_snippet.dart';
import '../migration/expression_annotations.dart';

/// [snippet] as Dart code to paste into a steps class, as method
/// [methodName]: the annotation, then a method that throws until it is
/// written.
List<String> snippetCode(StepSnippet snippet, String methodName) {
  final parameters = snippet.parameters.map((p) => p.declaration).join(', ');
  return [
    ExpressionAnnotations.annotationFor(snippet.expression, annotation: snippet.annotation),
    'Future<void> $methodName($parameters) async {',
    '  throw UnimplementedError();',
    '}',
  ];
}
