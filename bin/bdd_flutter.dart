import 'package:bdd_flutter/src/presentation/cli/bbd_cli.dart';

void main(List<String> arguments) async {
  final cli = BDDCLI();
  await cli.run(arguments);
}
