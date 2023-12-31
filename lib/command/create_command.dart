import 'dart:async';

import 'package:args/args.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:synk/upload/upload_request.dart';

import '../config/config.dart';
import '../config/database.dart';
import '../config/project.dart';
import '../terminal/changelog_reader.dart';
import '../terminal/console.dart';
import '../terminal/spinner.dart';
import '../upload/upload_service.dart';
import 'synk_command.dart';

class CreateCommand extends SynkCommand {
  final ProjectDatabase _db;
  final ModrinthApi _mr;
  final UploadServices _uploadServices;
  final SynkConfig _config;

  CreateCommand(this._db, this._mr, this._uploadServices, this._config)
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

    final projectId = console.promptValidated(
      "Project ID",
      (input) {
        if (!RegExp("[a-z-_]").hasMatch(input)) {
          return "$input is not a valid project ID, which must only contain lowercase English letters, hyphens and underscores";
        }

        if (_db.contains(input)) {
          return "A project with id '$input' already exists in the database, please pick something else";
        }

        return null;
      },
      defaultAnswer: displayName
          .toLowerCase()
          .runes
          .where((codeUnit) => codeUnit < 256)
          .map(String.fromCharCode)
          .join()
          .replaceAll(" ", "-"),
    );

    final loadersForType =
        loaders.where((element) => element.supportedProjectTypes.contains(type)).map((e) => e.name).toList();
    final chosenLoaders = loadersForType.length == 1
        ? [loadersForType.single]
        : console.chooseMultiple(
            _applyLoaderPreference(loadersForType),
            "Loader(s)",
            allowNone: false,
            formatter: (e) => e.capitalized,
          );

    final idByService = <String, String>{};
    if (console.ask("Set up platform-specific project IDs now", ephemeral: true)) {
      for (final service in _uploadServices.choose("Add another one")) {
        idByService[service.id] = await console.promptValidatedAsync(
          "${service.name} project ID",
          (input) async => !await Spinner.wait("Validating...", service.isProject(input))
              ? "No project with ID '$input' was found"
              : null,
          allowOverride: true,
        );
      }
    }

    final relations = <Relation>[];
    if (console.ask("Add relations", ephemeral: true)) {
      do {
        final relationName = console.prompt("Relation name");
        final relationType = console.choose(
          ModrinthDependencyType.values,
          "Relation type",
          formatter: (entry) => entry.name,
        );

        final idByService = <String, String>{};
        for (final service in _uploadServices.choose("Add dependency ID for another platform")) {
          idByService[service.id] = console.prompt("${service.name} dependency ID");
        }

        relations.add(Relation(relationName, relationType, idByService));
      } while (console.ask("Add another relation"));
    }

    String? primaryFilePattern;
    var secondaryFilePatterns = <String, String>{};
    if (console.ask("Set up artifact discovery", ephemeral: true)) {
      primaryFilePattern = console.prompt("Primary file pattern");

      if (console.ask("Add secondary file patterns")) {
        do {
          final patternId = console.prompt("Pattern ID", ephemeral: true);
          secondaryFilePatterns[patternId] = console.prompt("Secondary file pattern '$patternId'");
        } while (console.ask("Add another one", ephemeral: true));
      }
    }

    String? changelogFilePath;
    if (console.ask("Add a changelog file", ephemeral: true)) {
      changelogFilePath = console.prompt("Changelog file path");
    }

    final project = _db[projectId] = Project(
      type,
      displayName,
      projectId,
      chosenLoaders,
      relations,
      idByService,
      changelogFilePath,
      primaryFilePattern,
      secondaryFilePatterns,
    );
    _config.overlay = ConfigOverlay.ofProject(_db, project);

    if (console.ask("Use project-specific Minecraft versions", ephemeral: true)) {
      _config.minecraftVersions = console.chooseMultiple(versions, "Minecraft Versions", allowNone: false);
    }

    if (console.ask("Use project-specific changelog mode", ephemeral: true)) {
      _config.changelogReader = console.choose<ChangelogReader>(
        ChangelogReader.values,
        "Changelog Mode",
        formatter: (entry) => entry.name,
      );
    }

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
