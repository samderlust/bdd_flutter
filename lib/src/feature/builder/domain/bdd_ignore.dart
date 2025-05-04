import 'dart:io';

import 'package:yaml/yaml.dart';

class BDDIgnore {
  static final List<String> _ignoredFiles = [];
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    final ignoreFile = File('bdd_ignore.yaml');
    if (await ignoreFile.exists()) {
      final content = await ignoreFile.readAsString();
      final yaml = loadYaml(content);
      if (yaml is YamlMap && yaml['ignore_files'] is YamlList) {
        _ignoredFiles.addAll((yaml['ignore_files'] as YamlList).map((e) => e.toString()).toList());
      }
    }
    _isInitialized = true;
  }

  static bool shouldIgnore(String filePath) {
    return _ignoredFiles.contains(filePath);
  }
}
