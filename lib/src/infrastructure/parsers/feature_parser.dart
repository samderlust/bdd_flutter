import 'dart:io';

import 'package:bdd_flutter/src/domain/background.dart';

import '../../domain/decorator.dart';
import '../../domain/feature.dart';
import '../../domain/scenario.dart';
import '../../domain/step.dart';

class FeatureParser {
  Future<Feature> parseFeature(String filePath) async {
    // read files and parse the content

    final file = File(filePath);
    final fileContent = await file.readAsString();
    final lines = fileContent.split('\n').map((line) => line.trim()).toList();

    String? featureName;
    List<Scenario> scenarios = [];
    Set<Decorator> featureDecorators = {};

    Background? background;

    // scenario that is being process
    Scenario? currentScenario;
    // currrent scenario decorators that is being process
    List<Decorator> currentScenarioDecorators = [];
    // current scenario example that is being process
    // List<Map<String, String>> currentExamples = [];
    // List<String> exampleHeaders = [];

    // bool isParsingExamples = false;

    ExampleContent? currentExampleContent;

    bool isParsingBackground = false;

    //read each line
    for (var line in lines) {
      //get feature name
      if (line.startsWith('Feature:')) {
        featureName = line.substring('Feature:'.length).trim();
      }
      //parsing decorators
      else if (line.startsWith("@")) {
        //parsing feature decorators
        if (featureName == null) {
          // if lines start with @ and feature name is null,
          // it means it's a decorator for the feature
          featureDecorators.add(Decorator.fromString(line));
        }
        //parsing scenario decorators
        else {
          isParsingBackground = false;
          if (currentScenario != null) {
            // add currentScenario to the list and clear it and currentScenarioDecorators
            currentScenario.examples = currentExampleContent?.examples;

            scenarios.add(currentScenario);

            currentExampleContent = null;
            currentScenario = null;
            currentScenarioDecorators = [];
          }

          // if lines start with @ and feature name is not null,
          // it means it's a decorator for the scenario
          currentScenarioDecorators.add(Decorator.fromString(line));
        }
      }
      // start parsing background
      else if (line.startsWith('Background:')) {
        // if lines start with Background:, it means it's a background
        isParsingBackground = true;
        background = Background(
          description: line.substring('Background:'.length).trim(),
          steps: [],
        );
      }

      // parsing scenario name
      else if (line.startsWith('Scenario:')) {
        isParsingBackground = false;
        // isParsingExamples = false;
        // currentExampleContent = null;

        // if lines start with Scenario:, it means it's a scenario name
        final name = line.substring('Scenario:'.length).trim();
        if (currentScenario != null) {
          // if currentScenario is not null, add it to the list
          currentScenario.examples = currentExampleContent?.examples;
          // currentExampleContent = null;
          // add the current scenario to the list
          scenarios.add(currentScenario);
          // reset the examples
          // currentExamples = [];
          // exampleHeaders = [];
          currentExampleContent = null;
        }

        //create new scenario
        final decorators = currentScenarioDecorators.toSet();

        currentScenario = Scenario(
          name,
          [],
          decorators: decorators,
        );
        // Reset decorators and example content for next scenario
        currentScenarioDecorators = [];
        currentExampleContent = null;
      }
      // parsing steps
      else if (line.startsWith('Given') || line.startsWith('When') || line.startsWith('Then') || line.startsWith('And')) {
        // if lines start with Given, When, Then or And, it means it's a step
        final parts = line.split(' ');
        final stepType = parts[0];
        final stepText = parts.sublist(1).join(' ').trim();
        if (isParsingBackground) {
          background?.steps.add(Step(stepType, stepText));
        } else {
          currentScenario?.steps.add(Step(stepType, stepText));
        }
      }
      // check if start parsing example
      else if (line.startsWith('Examples:')) {
        // if lines start with Examples:, it means it's the start of examples
        currentExampleContent = ExampleContent();
      }
      // parsing example
      else if (currentExampleContent != null && line.isNotEmpty) {
        // if we are parsing examples and the line is not empty
        final cells = line.split('|').where((cell) => cell.trim().isNotEmpty).map((cell) => cell.trim()).toList();

        if (currentExampleContent.headers.isEmpty) {
          currentExampleContent.headers.addAll(cells);
        } else {
          currentExampleContent.values.add(cells);
        }
      }
    }

    if (currentScenario != null) {
      currentScenario.examples = currentExampleContent?.examples;
      scenarios.add(currentScenario);
    }

    return Feature(
      name: featureName ?? 'Unnamed Feature',
      path: filePath,
      scenarios: scenarios,
      decorators: featureDecorators.toSet(),
      background: background,
    );
  }
}

class ExampleContent {
  List<String> headers = [];
  List<List<String>> values = [];

  List<Map<String, String>> get examples {
    return values.map((value) => Map.fromIterables(headers, value)).toList();
  }
}
