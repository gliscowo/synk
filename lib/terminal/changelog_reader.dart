import 'dart:io';

import '../config/project.dart';
import 'console.dart';

const _changelogFilename = "changelog.md";
const _changelogFileTemplate = """


// Enter you changelog in this file and save it.
// Lines starting with '//' will be ignored
""";

enum ChangelogReader {
  editor,
  prompt,
  file;

  Future<String> getChangelog(Project project) async {
    switch (this) {
      case ChangelogReader.prompt:
        return console.prompt("Changelog");

      case ChangelogReader.file:
        return _readFile(File(project.changelogFilePath ?? _changelogFilename));

      case ChangelogReader.editor:
        final changelogFile = File(_changelogFilename);

        if (!changelogFile.existsSync() ||
            (changelogFile.readAsStringSync() != _changelogFileTemplate &&
                console.ask("Clear contents of '$_changelogFilename'"))) {
          changelogFile.writeAsStringSync(_changelogFileTemplate, flush: true);
        }

        // hey look, it appears that *not* doing async user-input
        // (like normal people) actually means that we don't have to
        // spawn a second isolate only to run the editor
        //
        // crazy!
        // i was crazy once
        await Process.start(
          Platform.environment["EDITOR"] ?? (Platform.isWindows ? "notepad" : "vi"),
          [_changelogFilename],
          mode: ProcessStartMode.inheritStdio,
        ).then((process) => process.exitCode);

        return _readFile(changelogFile);
    }
  }

  String _readFile(File file) {
    final lines = file
        .readAsLinesSync()
        .where((element) => !element.trimLeft().startsWith("//"))
        .skipWhile((value) => value.isEmpty)
        .toList();

    while (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }

    return lines.join("\n");
  }
}
