import 'package:synk/terminal/console.dart';

import 'synk.dart' as synk;

void main(List<String> args) async {
  while (true) {
    final runArgs = console.prompt("Run args").split(" ");
    if (runArgs case ["--exit"]) return;

    await synk.main(runArgs);
  }
}
