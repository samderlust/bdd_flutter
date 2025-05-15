import '../feature/logger/logger.dart';
import 'build_command.dart';
import 'domain/cmd_flag.dart';
import 'help_command.dart';

class CommandParser {
  final BuildCommand _buildCommand;
  final CLILogger _logger;

  CommandParser({BuildCommand? buildCommand, CLILogger? logger})
      : _buildCommand = buildCommand ?? BuildCommand(),
        _logger = logger ?? CLILogger();

  Future<void> parse(List<String> arguments) async {
    print('arguments: $arguments');
    if (arguments.isEmpty) {
      // Default to build command if no arguments provided
      await _buildCommand.generate([]);
      return;
    }

    final flags = arguments.map((argument) => CmdFlag.fromString(argument)).toList();
    print('flags: $flags');
    final error = CmdFlagValidator.validate(flags);

    if (error != null) {
      _logger.log(error, level: LogLevel.error);
      help(_logger);
      return;
    } else if (flags.contains(CmdFlag.help)) {
      help(_logger);
      return;
    } else {
      await _buildCommand.generate(flags);
    }

    // final command = arguments[0].toLowerCase();

    // if (arguments.contains('--help') || arguments.contains('-h')) {
    //   help(_logger);
    // } else if (_commands.contains(command)) {
    //   // Simple validation for mutually exclusive flags
    //   if ((arguments.contains('--force') || arguments.contains('-f')) && (arguments.contains('--new') || arguments.contains('-n'))) {
    //     _logger.log('Error: Cannot use --force with --new', level: LogLevel.error);
    //     help(_logger);
    //     return;
    //   } else {
    //     await _buildCommand.generate(arguments);
    //   }
    // } else {
    //   _logger.log('Unknown command: $command', level: LogLevel.error);
    //   help(_logger);
    // }
  }
}
