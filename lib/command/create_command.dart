import 'dart:async';

import 'package:args/args.dart';
import 'package:modrinth_api/modrinth_api.dart';

import '../config/database.dart';
import '../config/types.dart';
import '../terminal/ansi.dart' as c;
import '../terminal/console.dart';
import '../terminal/spinner.dart';
import 'synk_command.dart';

class CreateCommand extends SynkCommand {
  final ProjectDatabase _db;
  final ModrinthApi _mr;

  CreateCommand(this._db, this._mr)
      : super(
          "create",
          "Create a new project and store it in the database",
        );

  @override
  FutureOr<void> execute(ArgResults args) async {
    final loaders = (await Spinner.wait("Fetching loaders", _mr.tags.getLoaders())).toList();
    final versions = (await Spinner.wait("Fetching versions", _mr.tags.getGameVersions()))
        .where((e) => e.versionType == ModrinthGameVersionType.release)
        .map((e) => e.version)
        .toList();

    final type = console.choose(
      ModrinthProjectType.values,
      "Project Type",
      formatter: (type) => type.name.capitalized,
    );
    final displayName = console.prompt("Display Name");

    String projectId;
    while (true) {
      projectId = console.prompt(
        "Project ID",
        defaultAnswer: displayName
            .toLowerCase()
            .runes
            .where((codeUnit) => codeUnit < 256)
            .map(String.fromCharCode)
            .join()
            .replaceAll(" ", "-"),
      );

      if (_db.contains(projectId)) {
        print(
            "${c.yellow}!${c.reset} A project with id '$projectId' already exists in the database, please pick something else");
        console.moveCursor(up: 2);

        continue;
      }

      break;
    }

    final gameVersions = console.chooseMultiple(versions, "Minecraft Versions", allowNone: false);

    final loadersForType =
        loaders.where((element) => element.supportedProjectTypes.contains(type)).map((e) => e.name).toList();
    final chosenLoaders = loadersForType.length == 1
        ? [loadersForType.first]
        : console.chooseMultiple(
            _applyLoaderPreference(loadersForType),
            "Loader(s)",
            allowNone: false,
            formatter: (e) => e.capitalized,
          );

    // TODO collect ids by platform
    var project = _db[projectId] = Project(type, displayName, projectId, gameVersions, chosenLoaders, {});
    print(project.formatted);
  }

  List<String> _applyLoaderPreference(List<String> loaders) {
    loaders.sort();

    for (var (idx, loader) in const ["fabric", "quilt", "forge", "neoforge"].indexed) {
      if (!loaders.remove(loader)) continue;
      loaders.insert(idx, loader);
    }

    return loaders;
  }
}
