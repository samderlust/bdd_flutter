import 'package:bdd_flutter/src/generator/build_command.dart';
import 'package:bdd_flutter/src/runner/rename.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    await generate(arguments);
  } else if (arguments.first == 'rename') {
    print('rename');
    rename(arguments.skip(1).toList());
  }
}
