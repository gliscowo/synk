import 'dart:async';

import 'package:args/args.dart' show ArgResults;

import '../config/config.dart';
import '../config/database.dart';
import '../config/options.dart';
import '../config/project.dart';
import '../terminal/ansi.dart' as c;
import '../terminal/console.dart';
import 'synk_command.dart';

final _exitSentinel = Option("Save and exit", (_) {});

class EditCommand extends SynkCommand {
  final ProjectDatabase _db;
  final SynkConfig _config;
  final List<Option<SynkConfig>> _configOptions;
  final List<Option<Project>> _projectOptions;

  EditCommand(this._db, this._config, this._configOptions, this._projectOptions)
      : super(
          "edit",
          "Edit the given project",
          arguments: const ["project-id"],
        );

  @override
  FutureOr<void> execute(ArgResults args) async {
    final project = _db[args.rest.first];
    if (project == null) {
      print(c.error("No project with id '${args.rest.first}' found in database"));
      return;
    }

    print(project.formatted);

    final menuOptions = [..._projectOptions, _exitSentinel];
    while (true) {
      final option = console.choose(
        menuOptions,
        "Option to edit",
        formatter: (entry) => entry.name,
        ephemeral: true,
      );

      if (identical(_exitSentinel, option)) break;
      await option.update(project);
    }

    _db[project.projectId] = project;
    print(c.success("Changes applied"));
  }
}
