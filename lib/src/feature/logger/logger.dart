/// Log levels for different types of messages
enum LogLevel {
  info,
  warning,
  error,
}

/// A class to handle logging to the terminal
class CLILogger {
  static final CLILogger _instance = CLILogger._internal();
  factory CLILogger() => _instance;
  CLILogger._internal();

  /// Log a message with the specified level
  void log(String message, {LogLevel level = LogLevel.info}) {
    final prefix = _getPrefix(level);
    print('$prefix $message');
  }

  /// Log a message about skipping a file
  void logSkipping(String path, {String? reason}) {
    final message = reason != null ? 'Skipping $path ($reason)' : 'Skipping $path';
    log(message);
  }

  /// Log a message about processing a file
  void logProcessing(String path, {String? reason}) {
    final message = reason != null ? 'Processing $path ($reason)' : 'Processing $path';
    log(message);
  }

  /// Log a warning message
  void warning(String message) {
    log(message, level: LogLevel.warning);
  }

  /// Log an error message
  void error(String message) {
    log(message, level: LogLevel.error);
  }

  String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}
