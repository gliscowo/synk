import 'dart:async';

import 'package:args/args.dart' show ArgResults;

import '../config/config.dart';
import '../config/database.dart';
import '../config/options.dart';
import '../config/project.dart';
import '../terminal/ansi.dart' as c;
import '../terminal/console.dart';
import 'synk_command.dart';

final _exitSentinel = (Option("Save and exit", (_) {}), null);

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

    _config.overlay = ConfigOverlay.ofProject(_db, project);
    final menuOptions = [
      ..._projectOptions.map((e) => (e, project)),
      ..._configOptions.map((e) => (e, _config)),
      _exitSentinel,
    ];

    while (true) {
      final option = console.choose(
        menuOptions,
        "Option to edit",
        formatter: (entry) => entry.$1.name,
        ephemeral: true,
      );

      if (identical(_exitSentinel, option)) break;
      await option.$1.update(option.$2);
    }

    _db[project.projectId] = project;
    print(c.success("Changes applied"));

    _config.overlay = null;
  }
}
