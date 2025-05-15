import '../feature/logger/logger.dart';

void help(CLILogger logger) {
  logger.logLean('''
Usage: dart run bdd_flutter [options]

Options:
  --help, -h    Show this help message
  --force, -f   Force regenerate all feature files
  --new, -n     Only generate new feature files
  --unit-test, -u Generate unit tests (default: false)
  --reporter, -r Enable test reporter (default: false)

Examples:
  dart run bdd_flutter
  dart run bdd_flutter --force
  dart run bdd_flutter --new
  dart run bdd_flutter --unit-test
  dart run bdd_flutter --reporter

For more information, visit: https://github.com/samderlust/bdd_flutter
''');
}
