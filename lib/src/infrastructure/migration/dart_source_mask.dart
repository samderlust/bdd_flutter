/// Returns [source] with the contents of comments and string literals
/// replaced by spaces, keeping every index and line break in place.
///
/// Braces, semicolons and parentheses left in the result are real code, so
/// declarations can be found by counting them.
String maskDartSource(String source) => (_Masker(source)..scanCode(0)).result;

class _Masker {
  final String source;
  final List<String> _chars;

  _Masker(this.source) : _chars = source.split('');

  String get result => _chars.join();

  /// Scans code from [start]. With [untilBrace], stops at the `}` that
  /// closes a string interpolation and returns its index.
  int scanCode(int start, {bool untilBrace = false}) {
    var i = start;
    var depth = 0;
    while (i < source.length) {
      final skipped = _skipCommentOrString(i);
      if (skipped != null) {
        i = skipped;
        continue;
      }
      final char = source[i];
      if (untilBrace && char == '{') depth++;
      if (untilBrace && char == '}' && depth-- == 0) return i;
      i++;
    }
    return i;
  }

  /// The index after a comment or string starting at [i], or `null`.
  int? _skipCommentOrString(int i) {
    if (source.startsWith('//', i)) return _blankUntil(i, _indexOrEnd('\n', i));
    if (source.startsWith('/*', i)) {
      return _blankUntil(i, _indexOrEnd('*/', i + 2, extra: 2));
    }
    final char = source[i];
    if (char != "'" && char != '"') return null;
    return _scanString(i, raw: _isRawPrefix(i));
  }

  bool _isRawPrefix(int quote) {
    if (quote == 0 || source[quote - 1] != 'r') return false;
    return quote == 1 || !RegExp(r'\w').hasMatch(source[quote - 2]);
  }

  int _scanString(int start, {required bool raw}) {
    final quote = source[start];
    final delimiter = source.startsWith(quote * 3, start) ? quote * 3 : quote;
    var i = start + delimiter.length;
    while (i < source.length && !source.startsWith(delimiter, i)) {
      if (!raw && source[i] == r'\') {
        i += 2;
      } else if (!raw && source.startsWith(r'${', i)) {
        i = scanCode(i + 2, untilBrace: true) + 1;
      } else {
        i++;
      }
    }
    _blankUntil(start + delimiter.length, i);
    return i + delimiter.length;
  }

  int _indexOrEnd(String pattern, int from, {int extra = 0}) {
    final index = source.indexOf(pattern, from);
    return index < 0 ? source.length : index + extra;
  }

  int _blankUntil(int from, int to) {
    for (var k = from; k < to && k < source.length; k++) {
      if (_chars[k] != '\n') _chars[k] = ' ';
    }
    return to;
  }
}
