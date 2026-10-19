/// Accented Latin letters by the ASCII letter they fold to.
///
/// Covers Latin-1 Supplement, Latin Extended-A, the Vietnamese letters of
/// Latin Extended Additional, and the Romanian, Vietnamese and Pinyin
/// letters of Latin Extended-B.
const Map<String, String> _foldsTo = {
  'a': 'àáâãäåāăąǎạảấầẩẫậắằẳẵặ',
  'A': 'ÀÁÂÃÄÅĀĂĄǍẠẢẤẦẨẪẬẮẰẲẴẶ',
  'c': 'çćĉċč',
  'C': 'ÇĆĈĊČ',
  'd': 'ďđð',
  'D': 'ĎĐÐ',
  'e': 'èéêëēĕėęěẹẻẽếềểễệ',
  'E': 'ÈÉÊËĒĔĖĘĚẸẺẼẾỀỂỄỆ',
  'g': 'ĝğġģ',
  'G': 'ĜĞĠĢ',
  'h': 'ĥħ',
  'H': 'ĤĦ',
  'i': 'ìíîïĩīĭįıǐỉị',
  'I': 'ÌÍÎÏĨĪĬĮİǏỈỊ',
  'j': 'ĵ',
  'J': 'Ĵ',
  'k': 'ķĸ',
  'K': 'Ķ',
  'l': 'ĺļľŀł',
  'L': 'ĹĻĽĿŁ',
  'n': 'ñńņňŉŋ',
  'N': 'ÑŃŅŇŊ',
  'o': 'òóôõöøōŏőơǒọỏốồổỗộớờởỡợ',
  'O': 'ÒÓÔÕÖØŌŎŐƠǑỌỎỐỒỔỖỘỚỜỞỠỢ',
  'r': 'ŕŗř',
  'R': 'ŔŖŘ',
  's': 'śŝşšșſ',
  'S': 'ŚŜŞŠȘ',
  't': 'ţťŧț',
  'T': 'ŢŤŦȚ',
  'u': 'ùúûüũūŭůűųưǔǖǘǚǜụủứừửữự',
  'U': 'ÙÚÛÜŨŪŬŮŰŲƯǓǕǗǙǛỤỦỨỪỬỮỰ',
  'w': 'ŵ',
  'W': 'Ŵ',
  'y': 'ýÿŷỳỵỷỹ',
  'Y': 'ÝŸŶỲỴỶỸ',
  'z': 'źżž',
  'Z': 'ŹŻŽ',
};

/// Letters that fold to more than one ASCII letter.
const Map<String, String> _ligatures = {
  'ß': 'ss',
  'ẞ': 'SS',
  'æ': 'ae',
  'Æ': 'AE',
  'œ': 'oe',
  'Œ': 'OE',
  'þ': 'th',
  'Þ': 'TH',
  'ĳ': 'ij',
  'Ĳ': 'IJ',
};

/// Every accented letter mapped to its ASCII replacement.
final Map<int, String> _replacements = {
  for (final MapEntry(key: base, value: letters) in _foldsTo.entries)
    for (final letter in letters.runes) letter: base,
  for (final MapEntry(key: letter, value: ascii) in _ligatures.entries) letter.runes.single: ascii,
};

/// Combining Diacritical Marks, used when text is stored decomposed
/// (`e` followed by U+0301 instead of `é`).
bool _isCombiningMark(int rune) => rune >= 0x0300 && rune <= 0x036F;

/// Returns [text] with accented Latin letters replaced by plain ASCII ones:
/// `Tiếng Việt` → `Tieng Viet`, `Straße` → `Strasse`.
///
/// Characters outside the table, including other scripts, are kept.
String foldLatin(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (_isCombiningMark(rune)) continue;
    buffer.write(_replacements[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}
