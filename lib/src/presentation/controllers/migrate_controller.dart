import 'dart:io';

import '../../domain/config.dart';
import '../../domain/feature.dart';
import '../../domain/feature_files.dart';
import '../../infrastructure/formatting/code_formatter.dart';
import '../../infrastructure/migration/legacy_code_mapper.dart';
import '../../infrastructure/migration/legacy_scenarios_file.dart';
import '../../infrastructure/parsers/config_parser.dart';
import '../../infrastructure/parsers/feature_parser.dart';
import '../../infrastructure/steps/steps_catalog.dart';
import 'bdd_controller.dart';
import 'build_report.dart';

/// Moves a project from bdd_flutter 1.x to 2.0.
///
/// For every feature with a 1.x `.bdd_scenarios.dart` file and no
/// `_steps.dart` file yet, it creates the steps file with the user's 1.x
/// code carried over, generates the 2.0 files, and renames the 1.x file to
/// `.bdd_scenarios.dart.bak`.
class MigrateController {
  static const String _legacyManifest = '.bdd_flutter/manifest.yaml';

  final ConfigParser _configParser;
  final CodeFormatter _formatter;
  final BDDController _buildController;

  MigrateController({FeatureParser? featureParser, ConfigParser? configParser, CodeFormatter? formatter})
    : _configParser = configParser ?? ConfigParser(),
      _formatter = formatter ?? const DartFormatCommand(),
      _buildController = BDDController(
        featureParser: featureParser,
        configParser: configParser,
        formatter: const NoFormatting(),
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
    await _formatter.formatFiles(report.writtenFiles);
    _removeLegacyManifest();
    stdout.writeln(
      migrated == 0
          ? 'Nothing to migrate: no .bdd_scenarios.dart file without a _steps.dart file.'
          : 'Migrated $migrated feature(s). Run `dart run bdd_flutter build` from now on.',
    );
    return report.failed;
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
    stdout.writeln('  Removed $_legacyManifest: 2.0 does not use it.');
  }
}
