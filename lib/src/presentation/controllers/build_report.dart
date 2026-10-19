import 'dart:io';

import '../../domain/feature.dart';
import '../../domain/rule.dart';
import '../../domain/scenario.dart';
import '../../infrastructure/builders/scenario_settings.dart';

/// Collects what a build did and prints it.
class BuildReport {
  final List<String> _written = [];
  final List<String> _warnings = [];
  final Set<String> _tags = {};
  int _generated = 0;
  int _skipped = 0;
  int _failed = 0;

  /// Number of `.feature` files that failed to parse.
  int get failed => _failed;

  /// Every file written, to be formatted.
  List<String> get writtenFiles => List.unmodifiable(_written);

  /// Records a written file.
  void written(String path, {bool created = false}) {
    _written.add(path);
    stdout.writeln('  ${created ? 'Created' : 'Generated'}: $path');
    if (path.endsWith('.bdd_test.dart')) _generated++;
  }

  /// Records a skipped feature with the reason in [message].
  void skip(String message) {
    _skipped++;
    stdout.writeln('  $message');
  }

  /// Records a feature that failed to parse.
  void fail(String message) {
    _failed++;
    stderr.writeln('  $message');
  }

  /// Records problems found in a user's steps file.
  void addWarnings(List<String> warnings) {
    _warnings.addAll(warnings);
    for (final warning in warnings) {
      stdout.writeln('  Warning: $warning');
    }
  }

  /// Prints a suggestion that is not a problem.
  void addTip(String tip) => stdout.writeln('  Tip: $tip');

  /// Records the `dart test` tags used by [feature].
  void addTags(Feature feature) {
    Iterable<String> scenarioTags(Scenario s) => [...s.tags, for (final t in s.examples) ...t.tags];
    Iterable<String> ruleTags(Rule r) => [...r.tags, ...r.scenarios.expand(scenarioTags)];
    final all = [...feature.tags, ...feature.scenarios.expand(scenarioTags), ...feature.rules.expand(ruleTags)];
    _tags.addAll(all.where(isValidTestTag));
  }

  /// Prints the totals and the tags to declare in `dart_test.yaml`.
  void printSummary() {
    final parts = [
      if (_generated > 0) 'Generated: $_generated',
      if (_skipped > 0) 'Skipped: $_skipped',
      if (_failed > 0) 'Failed: $_failed',
      if (_warnings.isNotEmpty) 'Warnings: ${_warnings.length}',
    ];
    stdout.writeln('Done. ${parts.join(', ')}.');
    if (_tags.isEmpty) return;
    final tags = _tags.toList()..sort();
    stdout.writeln('Tags used: ${tags.join(', ')}. Declare them in dart_test.yaml to avoid warnings from dart test.');
  }
}
