import 'dart:io';

import '../../domain/config.dart';
import '../../domain/feature.dart';
import '../../domain/feature_files.dart';
import '../../domain/shared_files.dart';
import '../../domain/step_definition.dart';
import '../../domain/steps_class.dart';
import '../../domain/unresolved_reason.dart';
import '../../domain/unresolved_step.dart';
import '../../infrastructure/builders/expression_step_calls.dart';
import '../../infrastructure/builders/expression_steps_file_builder.dart';
import '../../infrastructure/builders/test_file_builder.dart';
import '../../infrastructure/steps/steps_file_reader.dart';
import 'build_file_writer.dart';
import 'build_report.dart';
import 'undefined_steps.dart';

/// `build` for `steps_mode: expressions`: matches every step with the
/// Cucumber Expressions of the feature's steps class and the shared steps
/// mixin, writes the tests, and reports what the user has to fix.
///
/// It creates a steps file only when a feature has none, and never edits
/// one that exists: for undefined steps it prints snippets, as Cucumber
/// does, with the class each one belongs in.
class ExpressionsBuild {
  final StepsFileReader _reader;
  final ExpressionStepsFileBuilder _stepsFileBuilder;

  const ExpressionsBuild({
    StepsFileReader reader = const StepsFileReader(),
    ExpressionStepsFileBuilder stepsFileBuilder = const ExpressionStepsFileBuilder(),
  }) : _reader = reader,
       _stepsFileBuilder = stepsFileBuilder;

  /// Builds every feature in [features].
  Future<void> run(List<Feature> features, BDDConfig config, BuildReport report, BuildFileWriter write) async {
    final shared = _SharedContext.read(SharedFiles(config.testDir, stepsSuffix: config.stepsSuffix), _reader);
    final reported = <String>{};
    _warnOnce(report, reported, shared.problems);
    final sharedUsed = <StepDefinition>{};
    final undefined = UndefinedSteps(shared.files, shared.mixin);
    for (final feature in features) {
      final files = FeatureFiles(feature, stepsSuffix: config.stepsSuffix);
      if (_isUnmigrated1x(files)) {
        report.skip('Skipped (1.x scenarios file): ${feature.path}. Run `dart run bdd_flutter migrate` first.');
        continue;
      }
      final used = await _buildFeature(files, config, shared, report, reported, write, undefined);
      sharedUsed.addAll(used.where((d) => d.ownerName == shared.mixin?.name));
    }
    _warnUnused(report, shared.mixin, sharedUsed, shared.files.stepsPath);
    undefined.hints().forEach(report.addUndefinedStep);
  }

  bool _isUnmigrated1x(FeatureFiles files) {
    return File(files.legacyScenariosPath).existsSync() && !File(files.stepsPath).existsSync();
  }

  /// Builds one feature; returns the definitions its steps used.
  Future<Set<StepDefinition>> _buildFeature(
    FeatureFiles files,
    BDDConfig config,
    _SharedContext shared,
    BuildReport report,
    Set<String> reported,
    BuildFileWriter write,
    UndefinedSteps undefined,
  ) async {
    final testBuilder = TestFileBuilder(widgetTestsByDefault: config.generateWidgetTests);
    final needsTester = testBuilder.needsTester(files.feature);
    if (!File(files.stepsPath).existsSync()) {
      await write(files.stepsPath, _newStepsFile(files, config, shared, needsTester), created: true);
    }
    final stepsFile = _reader.read(files.stepsPath);
    final own = stepsFile.classNamed(files.stepsClass);
    final calls = ExpressionStepCalls(
      stepsClassName: files.stepsClass,
      own: own,
      shared: shared.mixin,
      sharedImport: SharedFiles.relativeImport(files.testPath, shared.files.stepsPath),
    );
    await write(files.testPath, testBuilder.build(files, calls));
    report.addTags(files.feature);
    _warnOnce(report, reported, [...stepsFile.problems, ...calls.problems].map((p) => '$p'));
    _reportFeature(report, files, own, calls, needsTester: needsTester);
    undefined.add(files, own, calls.unresolved);
    return calls.usedDefinitions;
  }

  String _newStepsFile(FeatureFiles files, BDDConfig config, _SharedContext shared, bool needsTester) {
    return _stepsFileBuilder.build(
      files,
      needsTester: needsTester,
      sharedMixin: shared.mixin?.name,
      sharedImport: shared.mixin == null ? null : SharedFiles.relativeImport(files.stepsPath, shared.files.stepsPath),
      mixinDeclaresTester: shared.declaresTester,
      additionalImports: config.additionalImports,
    );
  }

  void _reportFeature(
    BuildReport report,
    FeatureFiles files,
    StepsClass? own,
    ExpressionStepCalls calls, {
    required bool needsTester,
  }) {
    final featureFile = '${files.feature.fileName}.feature';
    report.addWarnings([
      if (own == null) '${files.stepsPath} has no class ${files.stepsClass}; every step of $featureFile is undefined.',
      for (final step in calls.unresolved)
        if (step.reason != UnresolvedReason.undefined) '$featureFile: ${_describe(step)}',
      ...calls.warnings,
      if (needsTester && own != null && !own.declaresTester)
        '${files.stepsPath}: $featureFile has widget tests; add `late WidgetTester tester;` to ${files.stepsClass}.',
    ]);
    _warnUnused(report, own, calls.usedDefinitions, files.stepsPath);
  }

  String _describe(UnresolvedStep step) {
    final text = '`${step.step.keyword} ${step.text}`';
    String where(StepDefinition d) => '${d.ownerName}.${d.methodName} (${d.location})';
    return switch (step.reason) {
      UnresolvedReason.undefined => 'undefined step $text.', // reported by UndefinedSteps
      UnresolvedReason.ambiguous => 'ambiguous step $text matches ${step.candidates.map(where).join(', ')}.',
      UnresolvedReason.missingSharedMixin =>
        'step $text is defined in ${step.candidates.first.ownerName}; mix it in with `with ${step.candidates.first.ownerName}`.',
    };
  }

  /// Warns about methods of [owner] none of whose definitions was [used]; a
  /// method with several annotations counts as used when one of them is.
  void _warnUnused(BuildReport report, StepsClass? owner, Set<StepDefinition> used, String path) {
    final usedMethods = {for (final d in used) d.methodName};
    final unused = owner?.steps.map((d) => d.methodName).where((m) => !usedMethods.contains(m)).toSet().toList() ?? [];
    if (unused.isEmpty) return;
    unused.sort();
    report.addWarnings(['$path has steps no feature uses: ${unused.join(', ')}.']);
  }

  void _warnOnce(BuildReport report, Set<String> reported, Iterable<String> messages) {
    report.addWarnings([
      for (final message in messages)
        if (reported.add(message)) message,
    ]);
  }
}

/// The shared steps mixin, if the project has one.
class _SharedContext {
  final SharedFiles files;
  final StepsClass? mixin;
  final bool declaresTester;
  final List<String> problems;

  const _SharedContext(this.files, this.mixin, {required this.declaresTester, required this.problems});

  factory _SharedContext.read(SharedFiles files, StepsFileReader reader) {
    final stepsFile = reader.read(files.stepsPath);
    final mixin = stepsFile.classNamed(files.mixinName);
    return _SharedContext(
      files,
      mixin,
      declaresTester: mixin?.declaresTester ?? false,
      problems: [for (final problem in stepsFile.problems) '$problem'],
    );
  }
}
