import '../constraints/file_constraint.dart';
import '../extensions/string_x.dart';
import 'feature.dart';

/// The files and class names generated for one feature.
///
/// For `test/cart/cart.feature` with feature name `Shopping cart`:
/// - `cart.bdd_steps.dart` holds `ShoppingCartStepsContract` (generated);
/// - `cart_steps.dart` holds `ShoppingCartSteps` (written by the user);
/// - `cart.bdd_test.dart` holds the tests (generated).
class FeatureFiles {
  /// The feature these files belong to.
  final Feature feature;

  /// Suffix of the steps class name, `Steps` by default.
  final String stepsSuffix;

  const FeatureFiles(this.feature, {this.stepsSuffix = 'Steps'});

  String get _base {
    final path = feature.path;
    return path.substring(0, path.length - FileConstraint.feature.length);
  }

  String get _directory {
    final path = feature.path;
    return path.substring(0, _lastSeparator(path) + 1);
  }

  /// Path of the generated contract, e.g. `test/cart/cart.bdd_steps.dart`.
  String get contractPath => '$_base${FileConstraint.generatedSteps}';

  /// Path of the user's steps file, e.g. `test/cart/cart_steps.dart`.
  String get stepsPath => '$_directory${feature.fileName}${FileConstraint.userSteps}';

  /// Path of the generated test file, e.g. `test/cart/cart.bdd_test.dart`.
  String get testPath => '$_base${FileConstraint.generatedTest}';

  /// Path of the 1.x scenarios file, e.g. `test/cart/cart.bdd_scenarios.dart`.
  String get legacyScenariosPath => '$_base${FileConstraint.legacyScenarios}';

  /// File name of the contract, for imports.
  String get contractFileName => contractPath.substring(_lastSeparator(contractPath) + 1);

  /// File name of the steps file, for imports.
  String get stepsFileName => stepsPath.substring(_lastSeparator(stepsPath) + 1);

  /// The class the user implements, e.g. `ShoppingCartSteps`.
  String get stepsClass {
    final name = feature.name.name;
    // `Shared` + suffix is the shared steps mixin; keep the names apart.
    return name == 'Shared' ? 'SharedFeature$stepsSuffix' : '$name$stepsSuffix';
  }

  /// The generated interface, e.g. `ShoppingCartStepsContract`.
  String get contractClass => '${stepsClass}Contract';
}

/// Index of the last `/` or `\` in [path], or -1.
int _lastSeparator(String path) {
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf(r'\');
  return slash > backslash ? slash : backslash;
}
