import 'dart:async';

import 'package:args/args.dart';

import '../config/database.dart';
import '../terminal/ansi.dart' as c;
import 'synk_command.dart';

class IndexCommand extends SynkCommand {
  final ProjectDatabase _db;
  IndexCommand(this._db)
      : super(
          "index",
          "List the database index",
        );

  @override
  FutureOr<void> execute(ArgResults args) async {
    final index = _db.index;
    if (index.isEmpty) {
      print("${c.yellow}The database is currently empty");
      return;
    }

    print(_db.index.map((e) => e.formatted).join("\n"));
  }
}
