import 'dart:io';

import '../../infrastructure/parsers/feature_parser.dart';

import '../../infrastructure/builders/scenario_file_builder.dart';
import '../../infrastructure/builders/test_file_builder.dart';

class BDDController {
  final FeatureParser _featureParser;
  final ScenariosFileBuilder _scenarioFileBuilder;
  final TestFileBuilder _testFileBuilder;

  BDDController({
    FeatureParser? featureParser,
    ScenariosFileBuilder? scenarioFileBuilder,
    TestFileBuilder? testFileBuilder,
  })  : _featureParser = featureParser ?? FeatureParser(),
        _scenarioFileBuilder = scenarioFileBuilder ?? ScenariosFileBuilder(),
        _testFileBuilder = testFileBuilder ?? TestFileBuilder();

  Future<void> generateFeatureTestCases() async {
    final featureFiles = Directory('test/')
        .listSync(recursive: true)
        .where((file) => file.path.endsWith('.feature'));

    if (featureFiles.isEmpty) {
      stdout.writeln('No .feature files found in test/ directory.');
      return;
    }

    stdout.writeln('Found ${featureFiles.length} feature file(s).');

    for (var featureFile in featureFiles) {
      final feature = await _featureParser.parseFeature(featureFile.path);
      final scenarioContent = await _scenarioFileBuilder.buildScenarioFile(feature);
      final testContent = await _testFileBuilder.buildTestFile(feature);

      final scenarioPath = feature.path.replaceAll('.feature', '.bdd_scenarios.dart');
      final testPath = feature.path.replaceAll('.feature', '.bdd_test.dart');

      await File(scenarioPath).writeAsString(scenarioContent);
      await File(testPath).writeAsString(testContent);

      stdout.writeln('  Generated: $scenarioPath');
      stdout.writeln('  Generated: $testPath');
    }

    stdout.writeln('Done.');
  }
}
