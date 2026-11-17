import 'dart:io';

import '../../domain/config.dart';
import '../../domain/feature.dart';
import '../../domain/feature_files.dart';
import '../../domain/shared_files.dart';
import '../../domain/step_keyword_type.dart';
import '../../domain/steps_mode.dart';
import '../../infrastructure/formatting/code_formatter.dart';
import '../../infrastructure/migration/legacy_code_mapper.dart';
import '../../infrastructure/migration/expression_annotations.dart';
import '../../infrastructure/migration/legacy_scenarios_file.dart';
import '../../infrastructure/migration/steps_source_rewriter.dart';
import '../../infrastructure/steps/steps_file_reader.dart';
import '../../infrastructure/parsers/config_parser.dart';
import '../../infrastructure/parsers/feature_parser.dart';
import '../../infrastructure/steps/steps_catalog.dart';
import 'bdd_controller.dart';
import 'build_report.dart';

/// Moves a project to the current bdd_flutter.
///
/// First, for every feature with a 1.x `.bdd_scenarios.dart` file and no
/// `_steps.dart` file yet, it creates a 2.x steps file with the user's 1.x
/// code carried over and renames the 1.x file to `.bdd_scenarios.dart.bak`.
///
/// Then, with `steps_mode: expressions` (the default), it moves every 2.x
/// steps file and the shared steps mixin to Cucumber Expressions: each step
/// method gets `@Given`, `@When` or `@Then` (after its first step's keyword)
/// with an expression built from its 2.x step text, `implements` and
/// `@override` go, the `.bdd_steps.dart` contracts are deleted, and the tests
/// are rebuilt. Method signatures and bodies do not change. With
/// `steps_mode: contract` it stops after the 1.x step.
class MigrateController {
  static const String _legacyManifest = '.bdd_flutter/manifest.yaml';

  final ConfigParser _configParser;
  final CodeFormatter _formatter;
  final BDDController _buildController;
  final BDDController _rebuildController;
  final StepsSourceRewriter _rewriter;
  final StepsFileReader _reader = const StepsFileReader();

  MigrateController({
    FeatureParser? featureParser,
    ConfigParser? configParser,
    CodeFormatter? formatter,
    StepsSourceRewriter rewriter = const StepsSourceRewriter(),
  }) : _configParser = configParser ?? ConfigParser(),
       _formatter = formatter ?? const DartFormatCommand(),
       _rewriter = rewriter,
       _buildController = BDDController(
         featureParser: featureParser,
         configParser: configParser,
         formatter: const NoFormatting(),
       ),
       _rebuildController = BDDController(
         featureParser: featureParser,
         configParser: configParser,
         formatter: formatter ?? const DartFormatCommand(),
       );

  /// Migrates every 1.x feature. Returns the number that failed.
  Future<int> migrate() async {
    final config = await _configParser.loadConfig();
    final paths = _buildController.findFeatureFiles(config);
    if (paths == null) return 0;

    final report = BuildReport();
    final features = await _buildController.parseFeatures(paths, config, report);
    final catalog = StepsCatalog.of(features);
    var migrated = 0;
    for (final feature in features) {
      if (await _migrateFeature(feature, catalog, config, report)) migrated++;
    }
    if (config.stepsMode == StepsMode.expressions) {
      migrated += _migrateToExpressions(features, catalog, config, report);
    }
    await _formatter.formatFiles(report.writtenFiles);
    _removeLegacyManifest();
    if (migrated == 0) {
      stdout.writeln('Nothing to migrate: no 1.x scenarios file or 2.x steps contract found.');
      return report.failed;
    }
    stdout.writeln('Migrated $migrated file(s).');
    var failed = report.failed;
    if (config.stepsMode == StepsMode.expressions) {
      stdout.writeln('Rebuilding the tests:');
      failed += await _rebuildController.generateFeatureTestCases();
    }
    stdout.writeln('Run `dart run bdd_flutter build` from now on.');
    return failed;
  }

  /// Moves every 2.x steps file, then the shared mixin, to expressions.
  /// Returns the number of files changed.
  int _migrateToExpressions(List<Feature> features, StepsCatalog catalog, BDDConfig config, BuildReport report) {
    final shared = SharedFiles(config.testDir, stepsSuffix: config.stepsSuffix);
    final mixinDeclaresTester = _reader.read(shared.stepsPath).classNamed(shared.mixinName)?.declaresTester ?? false;
    var changed = 0;
    for (final feature in features) {
      final files = FeatureFiles(feature, stepsSuffix: config.stepsSuffix);
      if (_migrateStepsFile(files, _expressionsFor([feature], catalog), shared, mixinDeclaresTester, report)) {
        changed++;
      }
    }
    if (_migrateSharedMixin(shared, _expressionsFor(features, catalog, sharedOnly: true), report)) changed++;
    return changed;
  }

  bool _migrateStepsFile(
    FeatureFiles files,
    Map<String, List<String>> expressions,
    SharedFiles shared,
    bool mixinDeclaresTester,
    BuildReport report,
  ) {
    final stepsFile = File(files.stepsPath);
    final contract = File(files.contractPath);
    if (!stepsFile.existsSync()) return false;
    final source = stepsFile.readAsStringSync();
    if (!contract.existsSync() && !source.contains('implements ${files.contractClass}')) return false;
    final result = _rewriter.rewrite(
      source,
      ownerName: files.stepsClass,
      annotations: expressions,
      contractClass: files.contractClass,
      contractFileName: files.contractFileName,
      keepTesterOverride: mixinDeclaresTester && source.contains('with ${shared.mixinName}'),
    );
    if (!result.ownerFound) {
      report.addWarnings([
        '${files.stepsPath} has no class ${files.stepsClass}; not migrated, ${files.contractFileName} kept. '
            'Rename the class or add the annotations by hand.',
      ]);
      return false;
    }
    stepsFile.writeAsStringSync(result.source);
    report.updated(files.stepsPath);
    if (contract.existsSync()) contract.deleteSync();
    stdout.writeln('  Migrated ${files.stepsPath}: ${result.annotated.length} step(s) annotated, contract removed.');
    return true;
  }

  bool _migrateSharedMixin(SharedFiles shared, Map<String, List<String>> expressions, BuildReport report) {
    final file = File(shared.stepsPath);
    if (!file.existsSync()) return false;
    final result = _rewriter.rewrite(file.readAsStringSync(), ownerName: shared.mixinName, annotations: expressions);
    if (result.annotated.isEmpty) return false;
    file.writeAsStringSync(result.source);
    report.updated(shared.stepsPath);
    stdout.writeln('  Migrated ${shared.stepsPath}: ${result.annotated.length} step(s) annotated.');
    return true;
  }

  /// The annotations for each 2.x method name of [features], in step order,
  /// only for steps used by several features when [sharedOnly] (the shared
  /// mixin's steps; 2.x names are worked out per feature, so a name of a
  /// feature-only step can stand for another step elsewhere),
  /// e.g. `@When('I add {num} {string}')`. The annotation name follows the
  /// keyword of the method's first step. A method gets several annotations
  /// when its steps need different expressions, e.g. quoted text in one step
  /// and a bare `<column>` in another.
  Map<String, List<String>> _expressionsFor(List<Feature> features, StepsCatalog catalog, {bool sharedOnly = false}) {
    final names = <String, String>{};
    final expressions = <String, List<String>>{};
    for (final feature in features) {
      StepKeywordType? previous;
      for (final (step, pattern) in catalog.patternsIn(feature)) {
        final stepMethod = catalog.methodOf(feature, pattern);
        final method = stepMethod.name;
        if (sharedOnly && catalog.featuresUsing(stepMethod).length < 2) {
          if (!ExpressionAnnotations.isConjunction(step.keywordType)) previous = step.keywordType;
          continue;
        }
        names.putIfAbsent(method, () => ExpressionAnnotations.annotationNameFor(step.keywordType, previous: previous));
        if (!ExpressionAnnotations.isConjunction(step.keywordType)) previous = step.keywordType;
        final list = expressions.putIfAbsent(method, () => []);
        final expression = ExpressionAnnotations.expressionOf(step, pattern);
        if (!list.contains(expression)) list.add(expression);
      }
    }
    return {
      for (final MapEntry(:key, :value) in expressions.entries)
        key: [for (final e in value) ExpressionAnnotations.annotationFor(e, annotation: names[key]!)],
    };
  }

  /// Migrates [feature] if it has a 1.x file and no steps file yet. The new
  /// steps class declares every step itself, shared ones included, so it
  /// compiles before any shared steps are moved into the shared mixin.
  Future<bool> _migrateFeature(Feature feature, StepsCatalog catalog, BDDConfig config, BuildReport report) async {
    final files = FeatureFiles(feature, stepsSuffix: config.stepsSuffix);
    final legacyFile = File(files.legacyScenariosPath);
    if (!legacyFile.existsSync() || File(files.stepsPath).existsSync()) {
      return false;
    }

    final legacy = LegacyScenariosFile.parse(legacyFile.readAsStringSync());
    final mapper = LegacyCodeMapper(scenarioSuffix: config.legacyScenarioSuffix);
    final mapping = mapper.map(feature, catalog, legacy);
    await _buildController.writeGeneratedFiles(files, config, catalog, report: report, stubContent: mapping.content);
    legacyFile.renameSync('${files.legacyScenariosPath}.bak');
    stdout.writeln(
      '  Migrated ${files.legacyScenariosPath}: ${mapping.copied} step(s) copied, '
      '${mapping.toReview} to adapt by hand (marked with a throw). Old file kept as .bak.',
    );
    return true;
  }

  void _removeLegacyManifest() {
    final manifest = File(_legacyManifest);
    if (!manifest.existsSync()) return;
    manifest.deleteSync();
    stdout.writeln('  Removed $_legacyManifest: 2.0 and later do not use it.');
  }
}
