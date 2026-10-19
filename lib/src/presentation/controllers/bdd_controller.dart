import 'dart:io';

import '../../domain/config.dart';
import '../../domain/feature.dart';
import '../../domain/feature_files.dart';
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
/// For each `.feature` file it rewrites the steps contract and the test
/// file, and creates the user's steps file once. It never changes a file
/// the user owns.
class BDDController {
  final FeatureParser _featureParser;
  final ConfigParser _configParser;
  final CodeFormatter _formatter;
  final StepsContractBuilder _contractBuilder;
  final StepsStubBuilder _stubBuilder;

  BDDController({
    FeatureParser? featureParser,
    ConfigParser? configParser,
    CodeFormatter? formatter,
    StepsContractBuilder contractBuilder = const StepsContractBuilder(),
    StepsStubBuilder stubBuilder = const StepsStubBuilder(),
  }) : _featureParser = featureParser ?? const FeatureParser(),
       _configParser = configParser ?? ConfigParser(),
       _formatter = formatter ?? const DartFormatCommand(),
       _contractBuilder = contractBuilder,
       _stubBuilder = stubBuilder;

  /// Generates test files from every `.feature` file in the test directory.
  ///
  /// Returns the number of `.feature` files that failed to parse.
  Future<int> generateFeatureTestCases() async {
    final config = await _configParser.loadConfig();
    final featurePaths = findFeatureFiles(config);
    if (featurePaths == null) return 0;

    final report = BuildReport();
    for (final path in featurePaths) {
      await _buildFeature(path, config, report);
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

  Future<void> _buildFeature(String path, BDDConfig config, BuildReport report) async {
    if (config.ignoreFeatures.any(path.endsWith)) {
      report.skip('Skipped (config): $path');
      return;
    }
    final Feature feature;
    try {
      feature = await _featureParser.parseFeature(path);
    } on FeatureParseException catch (e) {
      report.fail('Failed: $e');
      return;
    }
    final files = FeatureFiles(feature, stepsSuffix: config.stepsSuffix);
    if (File(files.legacyScenariosPath).existsSync() && !File(files.stepsPath).existsSync()) {
      report.skip('Skipped (1.x scenarios file): $path. Run `dart run bdd_flutter migrate` first.');
      return;
    }
    await writeGeneratedFiles(files, config, report: report);
  }

  /// Writes the contract and test file for [files], and the steps file if
  /// it does not exist yet.
  Future<void> writeGeneratedFiles(
    FeatureFiles files,
    BDDConfig config, {
    BuildReport? report,
    StepsStubContent stubContent = const StepsStubContent(),
  }) async {
    final buildReport = report ?? BuildReport();
    final testBuilder = TestFileBuilder(widgetTestsByDefault: config.generateWidgetTests);
    final catalog = StepsCatalog.of(files.feature);
    final needsTester = testBuilder.needsTester(files.feature);

    await _write(files.contractPath, _contractBuilder.build(files, catalog, needsTester: needsTester), buildReport);
    await _write(files.testPath, testBuilder.build(files, catalog), buildReport);
    buildReport.addTags(files.feature);

    final stepsFile = File(files.stepsPath);
    if (stepsFile.existsSync()) {
      buildReport.addWarnings(checkStepsFile(stepsFile.readAsStringSync(), files.stepsPath, catalog));
      return;
    }
    final stub = _stubBuilder.build(
      files,
      catalog,
      needsTester: needsTester,
      additionalImports: config.additionalImports,
      content: stubContent,
    );
    await _write(files.stepsPath, stub, buildReport, created: true);
  }

  Future<void> _write(String path, String content, BuildReport report, {bool created = false}) async {
    await File(path).writeAsString(content);
    report.written(path, created: created);
  }
}
