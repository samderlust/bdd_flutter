import 'package:bdd_flutter/src/runner/command_parser.dart';

void main(List<String> arguments) async {
  final parser = CommandParser();
  await parser.parse(arguments);
}
