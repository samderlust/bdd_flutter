import 'build_command.dart';
import '../feature/logger/logger.dart';
import 'help_command.dart';

class CommandParser {
  final BuildCommand _buildCommand;
  final CLILogger _logger;

  CommandParser({BuildCommand? buildCommand, CLILogger? logger})
      : _buildCommand = buildCommand ?? BuildCommand(),
        _logger = logger ?? CLILogger();

  Future<void> parse(List<String> arguments) async {
    if (arguments.isEmpty) {
      // Default to build command if no arguments provided
      await _buildCommand.generate(arguments);
      return;
    }

    final command = arguments[0].toLowerCase();
    final remainingArgs = arguments.sublist(1);

    switch (command) {
      case 'build':
        await _buildCommand.generate(remainingArgs);
        break;

      default:
        _logger.log('Unknown command: $command', level: LogLevel.error);
        help(_logger);
    }
  }
}
