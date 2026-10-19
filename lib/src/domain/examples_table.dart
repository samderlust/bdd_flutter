import 'decorator.dart';

/// One `Examples:` block of a Scenario Outline.
///
/// ```gherkin
/// @eu
/// Examples: Europe
///   | from   | qty |
///   | Berlin | 1   |
/// ```
class ExamplesTable {
  /// The text after `Examples:`, empty when the block has no name.
  final String name;

  /// One map per table row, from column header to cell value.
  final List<Map<String, String>> rows;

  /// Decorators written above this block; only `@skip` has an effect here.
  final Set<Decorator> decorators;

  /// Other tags written above this block, without the leading `@`.
  final Set<String> tags;

  const ExamplesTable({this.name = '', required this.rows, this.decorators = const {}, this.tags = const {}});

  @override
  String toString() => 'ExamplesTable(name: $name, rows: $rows, tags: $tags)';
}
