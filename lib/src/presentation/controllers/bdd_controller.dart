import 'dart:io';

import '../../domain/config.dart';
import '../../domain/feature.dart';
import '../../domain/feature_files.dart';
import '../../domain/shared_files.dart';
import '../../infrastructure/builders/shared_steps_builder.dart';
import '../../infrastructure/builders/steps_contract_builder.dart';
import '../../infrastructure/builders/steps_stub_builder.dart';
import '../../infrastructure/builders/test_file_builder.dart';
import '../../infrastructure/formatting/code_formatter.dart';
import '../../infrastructure/parsers/config_parser.dart';
import '../../infrastructure/parsers/feature_parse_exception.dart';
import '../../infrastructure/parsers/feature_parser.dart';
import '../../infrastructure/steps/steps_catalog.dart';
import 'build_report.dart';
import 'steps_file_check.dart';

/// Orchestrates the BDD test generation pipeline.
///
/// It parses every `.feature` file first, so steps used by several features
/// get one name and go into the shared steps contract. Then, for each
/// feature, it rewrites the steps contract and the test file, and creates
/// the user's steps file once. It never changes a file the user owns.
class BDDController {
  final FeatureParser _featureParser;
  final ConfigParser _configParser;
  final CodeFormatter _formatter;
  final StepsContractBuilder _contractBuilder;
  final StepsStubBuilder _stubBuilder;
  final SharedStepsBuilder _sharedBuilder;

  BDDController({
    FeatureParser? featureParser,
    ConfigParser? configParser,
    CodeFormatter? formatter,
    StepsContractBuilder contractBuilder = const StepsContractBuilder(),
    StepsStubBuilder stubBuilder = const StepsStubBuilder(),
    SharedStepsBuilder sharedBuilder = const SharedStepsBuilder(),
  }) : _featureParser = featureParser ?? const FeatureParser(),
       _configParser = configParser ?? ConfigParser(),
       _formatter = formatter ?? const DartFormatCommand(),
       _contractBuilder = contractBuilder,
       _stubBuilder = stubBuilder,
       _sharedBuilder = sharedBuilder;

  /// Generates test files from every `.feature` file in the test directory.
  ///
  /// Returns the number of `.feature` files that failed to parse.
  Future<int> generateFeatureTestCases() async {
    final config = await _configParser.loadConfig();
    final featurePaths = findFeatureFiles(config);
    if (featurePaths == null) return 0;

    final report = BuildReport();
    final features = await parseFeatures(featurePaths, config, report);
    final catalog = StepsCatalog.of(features);
    final shared = SharedFiles(config.testDir, stepsSuffix: config.stepsSuffix);
    final sharedNeedsTester = _sharedNeedsTester(features, catalog, config);
    final hasSharedSteps = await _writeSharedFiles(shared, catalog, config, report, needsTester: sharedNeedsTester);
    for (final feature in features) {
      final files = FeatureFiles(feature, stepsSuffix: config.stepsSuffix);
      if (File(files.legacyScenariosPath).existsSync() && !File(files.stepsPath).existsSync()) {
        report.skip('Skipped (1.x scenarios file): ${feature.path}. Run `dart run bdd_flutter migrate` first.');
        continue;
      }
      await writeGeneratedFiles(
        files,
        config,
        catalog,
        report: report,
        shared: hasSharedSteps ? shared : null,
        sharedNeedsTester: sharedNeedsTester,
      );
    }
    await _formatter.formatFiles(report.writtenFiles);
    report.printSummary();
    return report.failed;
  }

  /// The `.feature` files to build, sorted, or `null` after printing why
  /// there are none.
  List<String>? findFeatureFiles(BDDConfig config) {
    final testDir = Directory(config.testDir);
    if (!testDir.existsSync()) {
      stdout.writeln('Directory "${config.testDir}" not found.');
      return null;
    }
    final paths = testDir.listSync(recursive: true).map((f) => f.path).where((p) => p.endsWith('.feature')).toList()
      ..sort();
    if (paths.isEmpty) {
      stdout.writeln('No .feature files found in "${config.testDir}".');
      return null;
    }
    stdout.writeln('Found ${paths.length} feature file(s).');
    return paths;
  }

  /// Parses [paths], leaving out ignored files and recording parse
  /// failures in [report].
  Future<List<Feature>> parseFeatures(List<String> paths, BDDConfig config, BuildReport report) async {
    final features = <Feature>[];
    for (final path in paths) {
      if (config.ignoreFeatures.any(path.endsWith)) {
        report.skip('Skipped (config): $path');
        continue;
      }
      try {
        features.add(await _featureParser.parseFeature(path));
      } on FeatureParseException catch (e) {
        report.fail('Failed: $e');
      }
    }
    return features;
  }

  /// Whether a feature that uses shared steps runs widget tests.
  bool _sharedNeedsTester(List<Feature> features, StepsCatalog catalog, BDDConfig config) {
    final testBuilder = TestFileBuilder(widgetTestsByDefault: config.generateWidgetTests);
    final sharedNames = catalog.sharedMethods.map((m) => m.name).toSet();
    return features.any(
      (f) => testBuilder.needsTester(f) && catalog.methodsFor(f).any((m) => sharedNames.contains(m.name)),
    );
  }

  /// Writes the shared contract, and the shared mixin if missing. Returns
  /// whether the shared mixin exists afterwards.
  Future<bool> _writeSharedFiles(
    SharedFiles shared,
    StepsCatalog catalog,
    BDDConfig config,
    BuildReport report, {
    required bool needsTester,
  }) async {
    final mixinFile = File(shared.stepsPath);
    if (catalog.sharedMethods.isEmpty && !mixinFile.existsSync()) return false;
    await _write(shared.contractPath, _sharedBuilder.buildContract(shared, catalog, needsTester: needsTester), report);
    if (mixinFile.existsSync()) {
      final names = catalog.sharedMethods.map((m) => m.name).toSet();
      report.addWarnings(checkStepsFile(mixinFile.readAsStringSync(), shared.stepsPath, needed: {}, provided: names));
      return true;
    }
    final mixin = _sharedBuilder.buildMixin(shared, catalog, additionalImports: config.additionalImports);
    await _write(shared.stepsPath, mixin, report, created: true);
    return true;
  }

  /// Writes the contract and test file for [files], and the steps file if
  /// it does not exist yet.
  ///
  /// With [shared], a new steps file mixes in the shared steps instead of
  /// declaring them.
  Future<void> writeGeneratedFiles(
    FeatureFiles files,
    BDDConfig config,
    StepsCatalog catalog, {
    BuildReport? report,
    StepsStubContent stubContent = const StepsStubContent(),
    SharedFiles? shared,
    bool sharedNeedsTester = false,
  }) async {
    final buildReport = report ?? BuildReport();
    final testBuilder = TestFileBuilder(widgetTestsByDefault: config.generateWidgetTests);
    final needsTester = testBuilder.needsTester(files.feature);

    await _write(files.contractPath, _contractBuilder.build(files, catalog, needsTester: needsTester), buildReport);
    await _write(files.testPath, testBuilder.build(files, catalog), buildReport);
    buildReport.addTags(files.feature);

    final ownNames = catalog.methodsFor(files.feature).map((m) => m.name).toSet();
    final sharedNames = ownNames.intersection(catalog.sharedMethods.map((m) => m.name).toSet());
    final stepsFile = File(files.stepsPath);
    if (stepsFile.existsSync()) {
      final source = stepsFile.readAsStringSync();
      final mixesIn = shared != null && source.contains('with ${shared.mixinName}');
      final needed = mixesIn ? ownNames.difference(sharedNames) : ownNames;
      buildReport.addWarnings(checkStepsFile(source, files.stepsPath, needed: needed, provided: sharedNames));
      return;
    }
    final use = shared == null || sharedNames.isEmpty
        ? null
        : SharedStepsUse(
            mixinName: shared.mixinName,
            importPath: SharedFiles.relativeImport(files.stepsPath, shared.stepsPath),
            methodNames: sharedNames,
          );
    final stub = _stubBuilder.build(
      files,
      catalog,
      needsTester: needsTester || (use != null && sharedNeedsTester),
      additionalImports: config.additionalImports,
      content: stubContent,
      shared: use,
    );
    await _write(files.stepsPath, stub, buildReport, created: true);
  }

  Future<void> _write(String path, String content, BuildReport report, {bool created = false}) async {
    await File(path).writeAsString(content);
    report.written(path, created: created);
  }
}
