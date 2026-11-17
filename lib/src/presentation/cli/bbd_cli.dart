import 'dart:io';

import '../../infrastructure/parsers/config_parser.dart';
import '../controllers/bdd_controller.dart';
import '../controllers/migrate_controller.dart';
import '../reporter/bdd_test_runner.dart';

/// CLI entry point for `dart run bdd_flutter`.
///
/// Supports commands:
/// - `build` — generate test files from `.feature` files
/// - `migrate` — move 1.x scenario files and 2.x steps files to the current
///   `steps_mode`
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
  ///
  /// An invalid config (e.g. an unknown `steps_mode`) is printed and exits
  /// with code 1.
  Future<void> run(List<String> arguments) async {
    try {
      await _run(arguments);
    } on FormatException catch (e) {
      stderr.writeln(e.message);
      exit(1);
    }
  }

  Future<void> _run(List<String> arguments) async {
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
    stdout.writeln(
      '  migrate  Move 1.x and 2.x steps files to Cucumber Expressions (or 1.x to 2.x with steps_mode: contract)',
    );
    stdout.writeln('  test     Run BDD tests with formatted report');
  }
}
