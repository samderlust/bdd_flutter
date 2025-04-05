import '../domain/bdd_options.dart';
import 'bdd_feature_builder.dart';
import 'bdd_test_file_builder.dart';
import 'scenario_file_builder.dart';

class BDDFactory {
  final BDDFeatureBuilder featureBuilder;
  final ScenariosFileBuilder scenarioBuilder;
  final BDDTestFileBuilder testFileBuilder;

  BDDFactory({
    required this.featureBuilder,
    required this.scenarioBuilder,
    required this.testFileBuilder,
  });

  factory BDDFactory.create(BDDOptions options) {
    return BDDFactory(
      featureBuilder: BDDFeatureBuilder(
        generateWidgetTests: options.generateWidgetTests,
      ),
      scenarioBuilder: ScenariosFileBuilder(),
      testFileBuilder: BDDTestFileBuilder(),
    );
  }
}
