/// Writes a file and records it in the build report.
typedef BuildFileWriter = Future<void> Function(String path, String content, {bool created});
