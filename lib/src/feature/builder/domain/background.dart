import 'package:bdd_flutter/src/feature/builder/domain/step.dart' show Step;

class Background {
  final String description;
  final List<Step> steps;

  Background({required this.description, required this.steps});
}
