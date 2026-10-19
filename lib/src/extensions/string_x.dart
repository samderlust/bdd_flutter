import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'latin_fold.dart';

/// Dart reserved words and built-in identifiers that cannot name a method,
/// parameter or class, plus `tester`, which generated steps classes use as
/// a field name, and the members every Dart object has.
const Set<String> _reserved = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const', //
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'type',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
  'tester', 'toString', 'hashCode', 'noSuchMethod', 'runtimeType',
};

/// String utilities for name conversion in code generation.
extension StringX on String {
  /// The ASCII words of this string, for building Dart identifiers.
  ///
  /// Accents are folded (`é` → `e`, `ệ` → `e`) and apostrophes join words
  /// (`j'incrémente` → `jincremente`). Everything else that is not a letter
  /// or digit separates words.
  List<String> get identifierWords {
    final folded = foldLatin(this).replaceAll(RegExp("['’]"), '');
    return folded.split(RegExp(r'[^a-zA-Z0-9]+')).where((word) => word.isNotEmpty).toList();
  }

  /// A short, stable hash of this string, for names of non-Latin text.
  String get shortHash => md5.convert(utf8.encode(this)).toString().substring(0, 6);

  /// Converts this string to a PascalCase Dart class name.
  ///
  /// Example: `"successful login"` → `"SuccessfulLogin"`, `"123 login"` →
  /// `"X123Login"`. Text with no Latin letters becomes `X` plus a hash.
  String get name {
    final words = identifierWords;
    if (words.isEmpty) return trim().isEmpty ? 'Unnamed' : 'X$shortHash';
    final result = words.map(_capitalize).join();
    return RegExp(r'^[0-9]').hasMatch(result) ? 'X$result' : result;
  }

  /// Converts this string to a camelCase Dart identifier for a method or
  /// parameter.
  ///
  /// Returns `null` when the text has no Latin letters or digits. A result
  /// that starts with a digit gets [prefix] in front; a reserved word gets
  /// `Step` appended.
  String? toCamelIdentifier({String prefix = 'step'}) {
    final words = identifierWords;
    if (words.isEmpty) return null;
    final result = _lowerFirst(words.first) + words.skip(1).map(_capitalize).join();
    if (RegExp(r'^[0-9]').hasMatch(result)) {
      return '$prefix${_capitalize(result)}';
    }
    return _reserved.contains(result) ? '${result}Step' : result;
  }

  /// This string as a single-quoted Dart string literal.
  ///
  /// Escapes backslashes, quotes, `$` and line breaks so the generated code
  /// produces exactly this value.
  String get toDartStringLiteral {
    final escaped = replaceAll(
      r'\',
      r'\\',
    ).replaceAll("'", r"\'").replaceAll(r'$', r'\$').replaceAll('\n', r'\n').replaceAll('\r', r'\r');
    return "'$escaped'";
  }
}

/// `user` → `User`, `syncNote` → `SyncNote`, `JSON` → `Json`.
String _capitalize(String word) {
  final rest = word.substring(1);
  return word[0].toUpperCase() + (word == word.toUpperCase() ? rest.toLowerCase() : rest);
}

/// `User` → `user`, `syncNote` → `syncNote`, `JSON` → `json`.
String _lowerFirst(String word) {
  if (word == word.toUpperCase()) return word.toLowerCase();
  return word[0].toLowerCase() + word.substring(1);
}
