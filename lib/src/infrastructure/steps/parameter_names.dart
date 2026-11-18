import '../../extensions/string_x.dart';

/// Names a snippet's parameters after the words around them in its
/// expression, where a guess is likely right:
///
/// - a number takes the word after it, its unit: `for {int} days` → `days`;
/// - other values take the noun a determiner introduces, before or after
///   them: `the coupon {string}` → `coupon`, `the {string} gift wrap` →
///   `giftWrap`.
///
/// Returns one name per `{parameter}` in [expression], in order; null where
/// no rule applies, so the caller keeps its default name.
List<String?> parameterNamesFrom(String expression, List<String> typeNames) {
  final placeholders = _placeholder.allMatches(expression).toList();
  return [
    for (var i = 0; i < placeholders.length; i++)
      _nameFor(
        _words(expression.substring(i == 0 ? 0 : placeholders[i - 1].end, placeholders[i].start)),
        _words(
          expression.substring(placeholders[i].end, i + 1 < placeholders.length ? placeholders[i + 1].start : null),
        ),
        isNumber: _numberTypes.contains(i < typeNames.length ? typeNames[i] : ''),
      ),
  ];
}

final RegExp _placeholder = RegExp(r'(?<!\\)\{[^}]*\}');

const Set<String> _numberTypes = {'int', 'float'};

const Set<String> _determiners = {'a', 'an', 'the', 'my', 'your', 'our', 'their', 'his', 'her', 'its', 'this', 'that'};

const Set<String> _stopWords = {
  ..._determiners,
  'and', 'or', 'but', 'as', 'at', 'in', 'on', 'of', 'to', 'for', 'with', 'by', 'from', 'into', 'per', 'each', 'than', //
  'is', 'are', 'was', 'were', 'be', 'been', 'has', 'have', 'had', 'i', 'we', 'you', 'it', 'me', 'us', 'them', //
};

String? _nameFor(List<String> before, List<String> after, {required bool isNumber}) {
  if (isNumber) return _usable(after.firstOrNull);
  final introduced = before.length >= 2 && _determiners.contains(before[before.length - 2]);
  if (introduced) return _usable(before.last);
  final introducesNext = before.isNotEmpty && _determiners.contains(before.last);
  return introducesNext ? _usable(_nounPhrase(after)) : null;
}

/// The words of [words] up to the first stop word, at most three:
/// `gift wrap for` → `gift wrap`.
String? _nounPhrase(List<String> words) {
  final phrase = words.takeWhile((w) => !_stopWords.contains(w)).take(3).join(' ');
  return phrase.isEmpty ? null : phrase;
}

String? _usable(String? word) {
  if (word == null || _stopWords.contains(word)) return null;
  return word.toCamelIdentifier(prefix: 'value');
}

List<String> _words(String text) => text.replaceAll(r'\', '').identifierWords.map((w) => w.toLowerCase()).toList();
