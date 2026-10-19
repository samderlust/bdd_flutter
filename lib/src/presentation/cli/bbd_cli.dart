import 'dart:io';

import '../../infrastructure/parsers/config_parser.dart';
import '../controllers/bdd_controller.dart';
import '../controllers/migrate_controller.dart';
import '../reporter/bdd_test_runner.dart';

/// CLI entry point for `dart run bdd_flutter`.
///
/// Supports commands:
/// - `build` — generate test files from `.feature` files
/// - `migrate` — move 1.x scenario files to 2.0 steps files
/// - `test` — run BDD tests with formatted report
class BDDCLI {
  final BDDController _bddController;
  final MigrateController _migrateController;
  final ConfigParser _configParser;

  BDDCLI({BDDController? bddController, MigrateController? migrateController, ConfigParser? configParser})
    : _bddController = bddController ?? BDDController(),
      _migrateController = migrateController ?? MigrateController(),
      _configParser = configParser ?? ConfigParser();

  /// Parses [arguments] and executes the corresponding command.
  Future<void> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      _printUsage();
      return;
    }

    final command = arguments.first;
    final flags = arguments.skip(1).toSet();

    switch (command) {
      case 'build':
        if (flags.contains('--force')) {
          stdout.writeln('Note: --force is no longer needed; build always rewrites the generated files.');
        }
        final failed = await _bddController.generateFeatureTestCases();
        if (failed > 0) exit(1);
      case 'migrate':
        final failed = await _migrateController.migrate();
        if (failed > 0) exit(1);
      case 'test':
        final config = await _configParser.loadConfig();
        final runner = BDDTestRunner(testDir: config.testDir);
        final exitCode = await runner.run();
        exit(exitCode);
      default:
        stdout.writeln('Unknown command: $command');
        _printUsage();
    }
  }

  void _printUsage() {
    stdout.writeln('Usage: dart run bdd_flutter <command>');
    stdout.writeln('');
    stdout.writeln('Available commands:');
    stdout.writeln('  build    Generate test files from .feature files');
    stdout.writeln('  migrate  Move 1.x .bdd_scenarios.dart files to 2.0 _steps.dart files');
    stdout.writeln('  test     Run BDD tests with formatted report');
  }
}
