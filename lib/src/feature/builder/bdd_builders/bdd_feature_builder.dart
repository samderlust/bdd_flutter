import '../domain/background.dart';
import '../domain/bdd_options.dart';
import '../domain/decorator.dart';
import '../domain/feature.dart';
import '../domain/scenario.dart';
import '../domain/step.dart';
import '../domain/validators/decorators_validator.dart';

class BDDFeatureBuilder {
  final BDDOptions options;

  BDDFeatureBuilder({required this.options});

  Feature parseFeature(String featureContent, String fileName) {
    final lines = featureContent.split('\n').map((line) => line.trim()).toList();
    String? featureName;
    List<Scenario> scenarios = [];
    List<Step> currentSteps = [];
    String? currentScenarioName;
    List<Map<String, String>>? currentExamples;
    List<String>? exampleHeaders;
    Set<BDDDecorator> featureDecorators = {};
    Set<BDDDecorator> currentScenarioDecorators = {};
    Background? background;
    Map<int, Set<BDDDecorator>> scenarioDecoratorsMap = {};

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('Feature:')) {
        featureName = line.substring('Feature:'.length).trim();
      } else if (line.startsWith('@ignore')) {
        // If @ignore is found, return an empty feature to skip generation
        return Feature('', [], fileName: fileName);
      } else if (line.startsWith('Background:')) {
        background = Background(
          description: line.substring('Background:'.length).trim(),
          steps: [],
        );
        i++;
        if (i < lines.length) {
          final backgroundLine = lines[i];
          if (backgroundLine.startsWith('Given') || backgroundLine.startsWith('When') || backgroundLine.startsWith('Then')) {
            background.steps.add(
              Step(
                backgroundLine.split(' ')[0],
                backgroundLine.substring(backgroundLine.split(' ')[0].length).trim(),
              ),
            );
          }
        }
      } else if (line.startsWith('@')) {
        if (featureName == null) {
          featureDecorators.add(BDDDecorator.fromString(line));
        } else {
          currentScenarioDecorators.add(BDDDecorator.fromString(line));
        }
      } else if (line.startsWith('Scenario:')) {
        // Store decorators for the current scenario before adding it
        if (currentScenarioName != null && currentSteps.isNotEmpty) {
          Set<BDDDecorator> tempDecorators = {};
          // Get decorators for the previous scenario
          if (scenarioDecoratorsMap[scenarios.length] != null) {
            tempDecorators = scenarioDecoratorsMap[scenarios.length]!;
          }
          final proccessedDecorators = _processDecorators(
            tempDecorators,
            featureDecorators,
          );
          scenarios.add(
            Scenario(
              currentScenarioName,
              List.from(currentSteps),
              examples: currentExamples,
              decorators: proccessedDecorators,
            ),
          );
          currentSteps.clear();
        }

        // Store decorators for the new scenario
        scenarioDecoratorsMap[scenarios.length] = {...currentScenarioDecorators};
        currentScenarioDecorators.clear();

        // if scenarios.isEmpty, which means the first scenario
        // here is the safe place to process the feature decorators for once
        if (scenarios.isEmpty) {
          featureDecorators = DecoratorsValidator.getValidFeatureDecorator(
            featureDecorators,
            options,
          );
        }
        currentScenarioName = line.substring('Scenario:'.length).trim();
        currentExamples = null;
        exampleHeaders = null;
      } else if (line.startsWith('Given') || line.startsWith('When') || line.startsWith('Then')) {
        final keyword = line.split(' ')[0];
        final text = line.substring(keyword.length).trim();
        currentSteps.add(Step(keyword, text));
      } else if (line.startsWith('Examples:')) {
        currentExamples = [];
        exampleHeaders = null;
        // Skip the header row
        i++;
        if (i < lines.length) {
          final headerLine = lines[i];
          if (headerLine.startsWith('|')) {
            exampleHeaders = headerLine.split('|').map((cell) => cell.trim()).where((cell) => cell.isNotEmpty).toList();
          }
        }
      } else if (line.startsWith('|') && currentExamples != null && exampleHeaders != null) {
        final cells = line.split('|').map((cell) => cell.trim()).where((cell) => cell.isNotEmpty).toList();

        if (cells.length == exampleHeaders.length) {
          currentExamples.add(Map.fromIterables(exampleHeaders, cells));
        }
      }
    }

    if (currentScenarioName != null && currentSteps.isNotEmpty) {
      final proccessedDecorators = _processDecorators(
        scenarioDecoratorsMap[scenarios.length] ?? {},
        featureDecorators,
      );

      final scenario = Scenario(
        currentScenarioName,
        currentSteps,
        examples: currentExamples,
        decorators: proccessedDecorators,
      );
      scenarios.add(scenario);
      currentScenarioDecorators.clear();
    }

    if (featureName == null) {
      throw Exception('No Feature defined in the file');
    }

    final feature = Feature(
      featureName,
      scenarios,
      fileName: fileName,
      background: background,
      decorators: featureDecorators,
    );
    // scenarioDecoratorsMap.clear();
    // currentScenarioDecorators.clear();
    // featureDecorators.clear();
    return feature;
  }

  /// pass the decorators from the feature and the scenario
  /// and return the decorators that should be used for the scenario
  /// decorators on the scenario will override the decorators on the feature
  Set<BDDDecorator> _processDecorators(
    Set<BDDDecorator> decorators,
    Set<BDDDecorator> featureDecorators,
  ) {
    DecoratorsValidator.validateScenarioDecorators(decorators);

    // If no decorators are specified, use the default from options
    if (!decorators.hasUnitTest && !decorators.hasWidgetTest) {
      if (!featureDecorators.hasUnitTest && !featureDecorators.hasWidgetTest) {
        return options.generateWidgetTests ? {...decorators, BDDDecorator.widgetTest()} : {...decorators, BDDDecorator.unitTest()};
      }
      return {...decorators, ...featureDecorators};
    }

    // if the feature has @unitTest and the scenario has @widgetTest,
    // then remove the @unitTest from the scenario decorators
    if (featureDecorators.hasUnitTest && decorators.hasWidgetTest) {
      return {...featureDecorators, ...decorators}..removeWhere((e) => e.isUnitTest);
    }
    // if the feature has @widgetTest and the scenario has @unitTest,
    // then remove the @widgetTest from the scenario decorators
    if (featureDecorators.hasWidgetTest && decorators.hasUnitTest) {
      return {...featureDecorators, ...decorators}..removeWhere((e) => e.isWidgetTest);
    }
    return {...featureDecorators, ...decorators};
  }
}
