import 'package:synk/terminal/ansi.dart' as c;
import 'package:synk/terminal/console.dart';

import 'synk.dart' as synk;

void main(List<String> args) async {
  while (true) {
    final runArgs = console.prompt("Run args").split(" ");
    if (runArgs case ["--exit"]) return;

    try {
      await synk.main(runArgs);
    } catch (ex, stack) {
      print(c.error("Run failed"));
      print(ex.toString().split("\n").map((e) => "|  $e").join("\n"));
      print(stack.toString().split("\n").map((e) => "|  $e").join("\n"));
    }
  }
}
