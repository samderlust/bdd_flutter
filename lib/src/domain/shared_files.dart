/// The files and names for steps shared by several features.
///
/// Both files live at the root of the test directory:
/// - `shared.bdd_steps.dart` holds `SharedStepsContract` (generated);
/// - `shared_steps.dart` holds `mixin SharedSteps` (written by the user).
class SharedFiles {
  /// The configured test directory, e.g. `test/`.
  final String testDir;

  /// Suffix of the steps class name, `Steps` by default.
  final String stepsSuffix;

  const SharedFiles(this.testDir, {this.stepsSuffix = 'Steps'});

  String get _directory => testDir.replaceAll(r'\', '/').replaceFirst(RegExp(r'/+$'), '');

  /// Path of the generated shared contract, e.g. `test/shared.bdd_steps.dart`.
  String get contractPath => '$_directory/shared.bdd_steps.dart';

  /// Path of the user's shared mixin, e.g. `test/shared_steps.dart`.
  String get stepsPath => '$_directory/shared_steps.dart';

  /// The mixin the user implements, e.g. `SharedSteps`.
  String get mixinName => 'Shared$stepsSuffix';

  /// The generated interface, e.g. `SharedStepsContract`.
  String get contractClass => '${mixinName}Contract';

  /// The import of [targetPath] as written in a file at [fromPath], e.g.
  /// `../shared_steps.dart` from `test/cart/cart_steps.dart`.
  static String relativeImport(String fromPath, String targetPath) {
    final from = fromPath.replaceAll(r'\', '/').split('/')..removeLast();
    final target = targetPath.replaceAll(r'\', '/').split('/');
    var shared = 0;
    while (shared < from.length && shared < target.length - 1 && from[shared] == target[shared]) {
      shared++;
    }
    return [for (var i = shared; i < from.length; i++) '..', ...target.skip(shared)].join('/');
  }
}
