import '../../domain/examples_table.dart';
import '../../domain/value_type.dart';

/// The type of each Examples column across all of a scenario's [tables].
///
/// A column missing from one table is filled there with its `<column>`
/// text, as Cucumber does, which makes that column a `String`.
Map<String, ValueType> columnTypes(List<ExamplesTable> tables) {
  final columns = {
    for (final table in tables)
      for (final row in table.rows) ...row.keys,
  };
  return {
    for (final column in columns)
      column: ValueType.ofAll([
        for (final table in tables)
          for (final row in table.rows) row[column] ?? '<$column>',
      ]),
  };
}
