import 'dart:io';

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

    switch (command) {
      case 'build':
        await _bddController.generateFeatureTestCases();
        break;
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
  }
}
