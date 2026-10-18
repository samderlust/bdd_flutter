import 'dart:io';

import 'package:cucumber_gherkin/cucumber_gherkin.dart';
import 'package:cucumber_messages/cucumber_messages.dart' as cm;

import '../../domain/feature.dart';
import 'feature_parse_exception.dart';
import 'gherkin_mapper.dart';

/// Parses Gherkin `.feature` files into [Feature] domain models.
///
/// Parsing is done by the official `cucumber_gherkin` parser, so the full
/// Gherkin grammar and all spoken languages are supported. [GherkinMapper]
/// then converts the result into bdd_flutter's own models.
class FeatureParser {
  final GherkinMapper _mapper;

  const FeatureParser({GherkinMapper mapper = const GherkinMapper()}) : _mapper = mapper;

  static const GherkinOptions _options = GherkinOptions(includeSource: false, includePickles: false);

  /// Parses a `.feature` file at [filePath] and returns a [Feature] model.
  ///
  /// Throws [FeatureParseException] when the file is not valid Gherkin.
  Future<Feature> parseFeature(String filePath) async {
    final content = await File(filePath).readAsString();
    final envelopes = generateMessages(content, filePath, _options);

    final errors = envelopes.map((e) => e.parseError).whereType<cm.ParseError>().toList();
    if (errors.isNotEmpty) {
      throw FeatureParseException(filePath, errors.map((e) => e.message).toList());
    }

    final document = envelopes.map((e) => e.gherkinDocument).whereType<cm.GherkinDocument>().first;
    return _mapper.toFeature(document, filePath);
  }
}
