import '../feature/logger/logger.dart';

void help() {
  final logger = CLILogger();
  logger.log('''
Usage: bdd_flutter <command> [options]

Commands:
  build: Build the test files
  clean: Clean the test files
  rename: Rename the test files
  help: Show the help
  version: Show the version
''');
}
