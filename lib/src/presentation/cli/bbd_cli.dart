import 'dart:io';

import '../../domain/build_options.dart';
import '../controllers/bdd_controller.dart';

class BDDCLI {
  final BDDController _bddController;

  BDDCLI({BDDController? bddController})
      : _bddController = bddController ?? BDDController();

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
    stdout.writeln('');
    stdout.writeln('Flags:');
    stdout.writeln('  --no-widget-test  Generate unit tests instead of widget tests');
    stdout.writeln('  --force           Force regenerate all files');
    stdout.writeln('  --new-only        Only generate for new feature files');
  }
}
