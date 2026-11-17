/// How steps are connected to code, set by `steps_mode` in the config.
enum StepsMode {
  /// 3.0 default: step methods carry Cucumber Expressions (`@When('...')`)
  /// and `build` matches each step against them.
  expressions('expressions'),

  /// 2.x behaviour: `build` generates a contract with one method per step,
  /// which the steps class implements.
  contract('contract');

  /// The value written in `config.yaml`.
  final String configValue;

  const StepsMode(this.configValue);

  /// The mode for a `steps_mode` [value]; [expressions] when it is null.
  ///
  /// Throws [FormatException] for any other value, so a typo never silently
  /// switches a 2.x project to expressions.
  static StepsMode parse(String? value) {
    if (value == null) return StepsMode.expressions;
    for (final mode in values) {
      if (mode.configValue == value) return mode;
    }
    throw FormatException(
      "Unknown steps_mode '$value' in .bdd_flutter/config.yaml. Use 'expressions' (default) or 'contract' (2.x).",
    );
  }
}
