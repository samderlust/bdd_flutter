import '../constraints/file_constraint.dart';

import 'background.dart';
import 'decorator.dart';
import 'scenario.dart';

class Feature {
  String name;
  String path;
  List<Scenario> scenarios;
  Background? background;
  Set<Decorator> decorators;

  Feature({
    required this.name,
    required this.path,
    required this.scenarios,
    required this.decorators,
    this.background,
  });
}

extension FeatureX on Feature {
  String get scenariosFileName {
    return '${fileName.replaceAll('.feature', '')}${FileConstraint.generatedScenarios}';
  }

  String get testFileName {
    return '${fileName.replaceAll('.feature', '')}${FileConstraint.generatedTest}';
  }

  String get fileName {
    return path.split('/').last.replaceAll('.feature', '');
  }
}
