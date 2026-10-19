/// Class and method names exactly as bdd_flutter 1.x generated them, so
/// `migrate` can find the user's 1.x code.
class LegacyNames {
  const LegacyNames._();

  /// 1.x class name: `"successful login"` → `"SuccessfulLogin"`.
  static String className(String text) {
    final words = _words(text);
    if (words.isEmpty) return 'Unnamed';
    final result = words.map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join();
    return RegExp(r'^[0-9]').hasMatch(result) ? 'X$result' : result;
  }

  /// 1.x method name for a step: placeholders keep their name, symbols
  /// split words and leading digits are dropped.
  static String methodName(String stepText) {
    final text = stepText.replaceAllMapped(RegExp(r'<(\w+)>'), (m) => m.group(1)!);
    final words = _words(text);
    if (words.isEmpty) return 'unnamed';
    final joined =
        words.first.toLowerCase() + words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join();
    final result = joined.replaceFirst(RegExp(r'^[0-9]+'), '');
    if (result.isEmpty) return 'step';
    return result[0].toLowerCase() + result.substring(1);
  }

  static List<String> _words(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }
}
