import 'package:bdd_flutter/src/infrastructure/parsers/feature_parse_exception.dart';
import 'package:bdd_flutter/src/infrastructure/parsers/gherkin_mapper.dart';
import 'package:cucumber_gherkin/cucumber_gherkin.dart';
import 'package:test/test.dart';

void main() {
  const mapper = GherkinMapper();
  const options = GherkinOptions(includeSource: false, includePickles: false);

  group('GherkinMapper.fromEnvelopes', () {
    test('maps a valid document to a feature', () {
      final envelopes = generateMessages('Feature: Cart\n  Scenario: Add\n    Given a cart\n', 'cart.feature', options);

      final feature = mapper.fromEnvelopes(envelopes, 'cart.feature');

      expect(feature.name, 'Cart');
      expect(feature.scenarios.single.steps.single.text, 'a cart');
    });

    test('throws FeatureParseException with every parse error', () {
      final envelopes = generateMessages(
        'Feature: Broken\n  Scenario: A\n    Given b\n  not Gherkin\n',
        'broken.feature',
        options,
      );

      expect(
        () => mapper.fromEnvelopes(envelopes, 'broken.feature'),
        throwsA(
          isA<FeatureParseException>()
              .having((e) => e.path, 'path', 'broken.feature')
              .having((e) => e.errors.single, 'error', startsWith('(4:3)')),
        ),
      );
    });

    test('throws FeatureParseException when no document is produced', () {
      expect(
        () => mapper.fromEnvelopes(const [], 'empty.feature'),
        throwsA(isA<FeatureParseException>().having((e) => e.errors, 'errors', ['No Gherkin document produced'])),
      );
    });
  });
}
