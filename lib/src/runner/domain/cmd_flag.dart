class CmdFlag {
  static const widgetTests = CmdFlag('--widget-test', '-w', 'Generate widget tests instead of unit tests, default is true', 'true');
  static const reporter = CmdFlag('--reporter', '-r', 'Enable reporter, default is false', 'false');
  static const ignore = CmdFlag('--ignore', '-i', 'Ignore features', '');
  static const force = CmdFlag('--force', '-f', 'Force generation', 'false');
  static const newOnly = CmdFlag('--new-only', '-n', 'Only generate new features', 'false');
  static const invalid = CmdFlag('--invalid', '', '', '');

  final String text;
  final String shortText;
  final String description;
  final String value;

  const CmdFlag(this.text, this.shortText, this.description, this.value);

  CmdFlag copyWith({String? text, String? shortText, String? description, String? value}) {
    return CmdFlag(
      text ?? this.text,
      shortText ?? this.shortText,
      description ?? this.description,
      value ?? this.value,
    );
  }

  @override
  String toString() {
    return '$text, $shortText, $description';
  }

  static List<CmdFlag> get values => [widgetTests, reporter, ignore, force, newOnly, invalid];

  static String getHelpText() {
    return values.where((flag) => flag != invalid).map((flag) => '${flag.text} (${flag.shortText}): ${flag.description}').join('\n');
  }

  static CmdFlag fromString(String text) {
    final parts = text.split(',');
    final flagText = parts.first;
    final value = parts.lastOrNull ?? '';

    return values
        .firstWhere(
          (flag) => flag.text == flagText || flag.shortText == flagText,
          orElse: () => invalid,
        )
        .copyWith(value: value);
  }
}
