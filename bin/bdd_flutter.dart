import 'package:bdd_flutter/src/runner/build_command.dart';
import 'package:bdd_flutter/src/runner/help_command.dart';
import 'package:bdd_flutter/src/runner/rename.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    await generate(arguments);
  } else {
    final command = BDDCommand.fromName(arguments.first);
    switchCase(command, arguments.skip(1).toList());
  }
}

void switchCase(BDDCommand command, List<String> arguments) {
  switch (command) {
    case BDDCommand.rename:
      rename(arguments);
      break;
    default:
      help();
      break;
  }
}

enum BDDCommand {
  build('build', 'Build the test files'),
  clean('clean', 'Clean the test files'),
  rename('rename', 'Rename the test files'),
  help('help', 'Show the help'),
  version('version', 'Show the version'),
  unknown('unknown', 'Unknown command');

  final String name;
  final String description;

  const BDDCommand(this.name, this.description);

  static BDDCommand fromName(String name) {
    return values.firstWhere((command) => command.name == name, orElse: () => unknown);
  }
}
