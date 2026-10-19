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
import 'shared_mixin.dart';
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
    report.addWarnings([for (final collision in catalog.nameCollisions) '$collision']);
    final mixin = await _sharedMixin(
      SharedFiles(config.testDir, stepsSuffix: config.stepsSuffix),
      features,
      catalog,
      config,
      report,
    );
    for (final feature in features) {
      final files = FeatureFiles(feature, stepsSuffix: config.stepsSuffix);
      if (File(files.legacyScenariosPath).existsSync() && !File(files.stepsPath).existsSync()) {
        report.skip('Skipped (1.x scenarios file): ${feature.path}. Run `dart run bdd_flutter migrate` first.');
        continue;
      }
      await writeGeneratedFiles(files, config, catalog, report: report, mixin: mixin);
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

  /// The user's shared steps mixin: read if it exists, created with stubs
  /// the first time steps are shared, `null` when there is none.
  ///
  /// Also suggests moving steps used by several features into the mixin,
  /// and warns about mixin steps no feature uses any more.
  Future<SharedMixin?> _sharedMixin(
    SharedFiles files,
    List<Feature> features,
    StepsCatalog catalog,
    BDDConfig config,
    BuildReport report,
  ) async {
    final existing = SharedMixin.read(files);
    if (existing == null && catalog.sharedMethods.isEmpty) return null;
    if (existing == null) return _createSharedMixin(files, features, catalog, config, report);

    final unused = existing.methods.difference(catalog.methods.map((m) => m.name).toSet()).toList()..sort();
    if (unused.isNotEmpty) {
      report.addWarnings(['${files.stepsPath} has steps no longer in any feature: ${unused.join(', ')}.']);
    }
    for (final method in catalog.sharedMethods.where((m) => !existing.provides(m))) {
      final users = catalog.featuresUsing(method).map((f) => f.split(RegExp(r'[/\\]')).last).join(', ');
      report.addTip(
        '`${method.stepMessages.first}` is used by $users. '
        'Move ${method.name} into ${files.mixinName} (${files.stepsPath}) to write it once.',
      );
    }
    return existing;
  }

  Future<SharedMixin> _createSharedMixin(
    SharedFiles files,
    List<Feature> features,
    StepsCatalog catalog,
    BDDConfig config,
    BuildReport report,
  ) async {
    final testBuilder = TestFileBuilder(widgetTestsByDefault: config.generateWidgetTests);
    final names = catalog.sharedMethods.map((m) => m.name).toSet();
    final needsTester = features.any(
      (f) => testBuilder.needsTester(f) && catalog.methodsFor(f).any((m) => names.contains(m.name)),
    );
    final source = _sharedBuilder.buildMixin(
      files,
      catalog.sharedMethods,
      needsTester: needsTester,
      additionalImports: config.additionalImports,
    );
    await _write(files.stepsPath, source, report, created: true);
    return SharedMixin(
      files,
      signatures: {
        for (final method in catalog.sharedMethods) method.name: [for (final p in method.parameters) p.dartType],
      },
      declaresTester: needsTester,
    );
  }

  /// Writes the contract and test file for [files], and the steps file if
  /// it does not exist yet.
  ///
  /// With [mixin], a new steps file mixes in the shared steps it uses
  /// instead of declaring them.
  Future<void> writeGeneratedFiles(
    FeatureFiles files,
    BDDConfig config,
    StepsCatalog catalog, {
    BuildReport? report,
    StepsStubContent stubContent = const StepsStubContent(),
    SharedMixin? mixin,
  }) async {
    final buildReport = report ?? BuildReport();
    final testBuilder = TestFileBuilder(widgetTestsByDefault: config.generateWidgetTests);
    final needsTester = testBuilder.needsTester(files.feature);

    await _write(files.contractPath, _contractBuilder.build(files, catalog, needsTester: needsTester), buildReport);
    await _write(files.testPath, testBuilder.build(files, catalog), buildReport);
    buildReport.addTags(files.feature);

    final own = catalog.methodsFor(files.feature);
    final ownNames = own.map((m) => m.name).toSet();
    final clashes = [
      for (final m in own)
        if (mixin?.clashesWith(m) ?? false) m.name,
    ];
    final provided = {
      for (final m in own)
        if (mixin?.provides(m) ?? false) m.name,
    };
    if (clashes.isNotEmpty) {
      buildReport.addWarnings([
        '${files.stepsPath}: ${mixin!.files.mixinName} has ${clashes.join(', ')} with other parameter types '
            'than ${files.feature.fileName}.feature needs. Rename the mixin method or reword the step.',
      ]);
    }
    final stepsFile = File(files.stepsPath);
    if (stepsFile.existsSync()) {
      final source = stepsFile.readAsStringSync();
      final mixesIn = mixin != null && source.contains('with ${mixin.files.mixinName}');
      final needed = mixesIn ? ownNames.difference(provided) : ownNames;
      buildReport.addWarnings(checkStepsFile(source, files.stepsPath, needed: needed, provided: provided));
      return;
    }
    final use = mixin == null || provided.isEmpty || clashes.isNotEmpty
        ? null
        : SharedStepsUse(
            mixinName: mixin.files.mixinName,
            importPath: SharedFiles.relativeImport(files.stepsPath, mixin.files.stepsPath),
            methodNames: provided,
          );
    final stub = _stubBuilder.build(
      files,
      catalog,
      needsTester: needsTester || (use != null && mixin!.declaresTester),
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
