import 'dart:async';

import 'package:args/args.dart';

import '../config/database.dart';
import '../terminal/ansi.dart' as c;
import '../terminal/console.dart';
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

    final project = _db[projectId];
    if (project == null) {
      print(c.error("No project with id '$projectId' found in database"));
      return;
    }

    if (!console.ask("Really delete '${project.displayName}'")) return;

    _db[projectId] = null;
    print(c.success("Project ${project.displayName} deleted successfully"));
  }
}
