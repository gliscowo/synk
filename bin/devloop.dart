import 'package:synk/terminal/console.dart';
import 'package:synk/upload/upload_service.dart';

import 'synk.dart' as synk;

void main(List<String> args) async {
  while (true) {
    final runArgs = console.prompt("Run args").split(" ");
    if (runArgs case ["--exit"]) return;

    UploadService.clearRegistry();
    await synk.main(runArgs);
  }
}
