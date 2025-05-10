import 'dart:io';

import '../constraints/file_extenstion.dart';

/// this will remove `.g` from the file name
///
/// suggested to run after writing test, this will prevent the file from being overwritten
/// the next time the build command is run
void rename(List<String> arguments) {
  // arg can be list of feature name, if not provided, all features will be renamed
  // if provided, only the features in the list will be renamed

  if (arguments.isEmpty) {
    print('No feature name provided, all features will be renamed');
  } else {
    print('Renaming features: ${arguments.join(', ')}');
  }

  final testDir = Directory('test');
  if (!testDir.existsSync()) {
    print('No test directory found');
    return;
  }

  final files = testDir
      .listSync(recursive: true)
      .where((file) => file.path.endsWith(FileExtension.generatedTest) || file.path.endsWith(FileExtension.generatedScenarios))
      .map((file) => File(file.path))
      .where((file) {
    if (arguments.isEmpty) return true;
    final featureName = file.path.split('/').last.split('.').first;
    return arguments.any((arg) => featureName.contains(arg));
  }).toList();

  if (files.isEmpty) {
    print('No generated files found to rename');
    return;
  }

  for (final file in files) {
    final newName = file.path.replaceAll('.bdd.', '.bdd_');
    print('Renaming ${file.path} to $newName');

    // Update import statements in the file
    final content = file.readAsStringSync();
    final updatedContent = content.replaceAll('.bdd.', '.bdd_');
    file.writeAsStringSync(updatedContent);

    // Rename the file
    file.renameSync(newName);
  }
}
