import 'dart:io';

import '../../domain/build_options.dart';
import '../../infrastructure/parsers/config_parser.dart';
import '../controllers/bdd_controller.dart';
import '../reporter/bdd_test_runner.dart';

class BDDCLI {
  final BDDController _bddController;
  final ConfigParser _configParser;

  BDDCLI({
    BDDController? bddController,
    ConfigParser? configParser,
  })  : _bddController = bddController ?? BDDController(),
        _configParser = configParser ?? ConfigParser();

  Future<void> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      _printUsage();
      return;
    }

    final command = arguments.first;
    final flags = arguments.skip(1).toSet();

    switch (command) {
      case 'build':
        final options = BuildOptions(
          widgetTest: !flags.contains('--no-widget-test'),
          force: flags.contains('--force'),
          newOnly: flags.contains('--new-only'),
        );
        await _bddController.generateFeatureTestCases(options: options);
        break;
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
    stdout.writeln('Usage: dart run bdd_flutter <command> [flags]');
    stdout.writeln('');
    stdout.writeln('Available commands:');
    stdout.writeln('  build    Generate test files from .feature files');
    stdout.writeln('  test     Run BDD tests with formatted report');
    stdout.writeln('');
    stdout.writeln('Build flags:');
    stdout.writeln('  --no-widget-test  Generate unit tests instead of widget tests');
    stdout.writeln('  --force           Force regenerate all files');
    stdout.writeln('  --new-only        Only generate for new feature files');
  }
}
