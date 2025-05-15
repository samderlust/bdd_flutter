import 'package:bdd_flutter/src/runner/command_parser.dart';
import 'dart:io';

void main(List<String> arguments) async {
  try {
    final parser = CommandParser();
    await parser.parse(arguments);
  } catch (e) {
    print('Error: ${e.toString()}');
    exit(1);
  }
}
