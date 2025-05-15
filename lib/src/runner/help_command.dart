import '../feature/logger/logger.dart';

void help(CLILogger logger) {
  logger.logLean('''
Usage: dart run bdd_flutter [options]

Options:
  --help    Show this help message
  --force   Force regenerate all feature files
  --new     Only generate new feature files
  --widget  Generate widget tests (default: false)
  --reporter Enable test reporter (default: false)

Examples:
  dart run bdd_flutter
  dart run bdd_flutter --force
  dart run bdd_flutter --new
  dart run bdd_flutter --widget
  dart run bdd_flutter --reporter

For more information, visit: [GitHub repository URL]
''');
}
