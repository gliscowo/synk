import 'dart:async';

import 'package:args/args.dart';
import 'package:synk/config/database.dart';
import 'package:synk/terminal/console.dart';

import '../terminal/ansi.dart' as c;
import 'synk_command.dart';

class DeleteCommand extends SynkCommand {
  final ProjectDatabase _db;
  DeleteCommand(this._db)
      : super(
          "delete",
          "Delete a project from the database",
          arguments: const ["project-id"],
        );

  @override
  FutureOr<void> execute(ArgResults args) async {
    final projectId = args.rest.first;

    if (!_db.contains(projectId)) {
      print("${c.red}No project with id '$projectId' found in database${c.reset}");
      return;
    }

    final project = _db[projectId];
    if (!console.ask("Really delete '${project!.displayName}'")) return;

    _db[projectId] = null;
    print("Project ${project.displayName} deleted successfully");
  }
}
