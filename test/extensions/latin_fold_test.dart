import 'package:bdd_flutter/src/extensions/latin_fold.dart';
import 'package:test/test.dart';

void main() {
  group('foldLatin', () {
    test('folds French, German, Spanish and Polish', () {
      expect(foldLatin("j'incrémente le compteur à 0"), "j'incremente le compteur a 0");
      expect(foldLatin('Straße Größe'), 'Strasse Grosse');
      expect(foldLatin('mañana niño'), 'manana nino');
      expect(foldLatin('Łódź żółć'), 'Lodz zolc');
    });

    test('folds Vietnamese stacked diacritics', () {
      expect(foldLatin('Tiếng Việt đường phố'), 'Tieng Viet duong pho');
      expect(foldLatin('Ước mơ Ở Đà Nẵng'), 'Uoc mo O Da Nang');
    });

    test('folds ligatures to several letters', () {
      expect(foldLatin('Æsir œuvre Þór'), 'AEsir oeuvre THor');
    });

    test('drops combining marks of decomposed text', () {
      expect(foldLatin('été'), 'ete');
    });

    test('keeps ASCII and other scripts unchanged', () {
      expect(foldLatin('plain ASCII 123 !?'), 'plain ASCII 123 !?');
      expect(foldLatin('カウンター Счётчик'), 'カウンター Счётчик');
    });

    test('folds every letter of Latin-1, Latin Extended-A and Vietnamese to ASCII', () {
      final letters = [
        for (var rune = 0x00C0; rune <= 0x017F; rune++)
          if (rune != 0x00D7 && rune != 0x00F7) rune,
        for (var rune = 0x1EA0; rune <= 0x1EF9; rune++) rune,
      ];
      final unfolded = [
        for (final rune in letters)
          if (!RegExp(r'^[A-Za-z]+$').hasMatch(foldLatin(String.fromCharCode(rune)))) String.fromCharCode(rune),
      ];

      expect(unfolded, isEmpty);
    });
  });
}
