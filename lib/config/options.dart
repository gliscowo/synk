import 'dart:async';

import 'package:modrinth_api/modrinth_api.dart';
import 'package:synk/upload/types.dart';

import '../terminal/ansi.dart' as c;
import '../terminal/changelog_reader.dart';
import '../terminal/console.dart';
import '../terminal/spinner.dart';
import '../upload/upload_service.dart';
import 'config.dart';
import 'types.dart';

final _addRelationSentinel = Relation("Add new", ModrinthDependencyType.required, const {});

class Option<H> {
  /// The name of this option to be displayed
  /// to the use in menus
  final String name;
  final FutureOr<void> Function(H) _updateFunc;

  Option(this.name, this._updateFunc);

  /// Ask the user to update the stored
  /// value of this option
  FutureOr<void> update(H holder) async => await _updateFunc(holder);
}

List<Option<SynkConfig>> createConfigOptions(ModrinthApi mr) => [
      Option("Changelog reader", (config) {
        config.changelogReader = console.choose<ChangelogReader>(
          ChangelogReader.values,
          "New default changelog reader",
          selected: ChangelogReader.values.indexOf(config.changelogReader),
          formatter: (entry) => entry.name,
        );
      }),
      Option("Default Minecraft Versions", (config) async {
        final versions = (await Spinner.wait("Fetching versions", mr.tags.getGameVersions()))
            .where((e) => e.versionType == ModrinthGameVersionType.release)
            .map((e) => e.version)
            .toList();

        final chosenVersions = console.chooseMultiple(
          versions,
          "Default minecraft versions",
          selected: config.minecraftVersions,
        );

        config.minecraftVersions = chosenVersions.isNotEmpty ? chosenVersions : null;
      })
    ];

List<Option<Project>> createProjectOptions(ModrinthApi mr) => [
      Option("Display Name", (project) {
        project.displayName = console.promptValidated(
          "New display name",
          (input) => input.isEmpty ? "The display name may not be empty" : null,
        );
      }),
      Option("Loaders", (project) async {
        final loaders = (await Spinner.wait("Fetching loaders", mr.tags.getLoaders()))
            .where((e) => e.supportedProjectTypes.contains(project.type))
            .map((e) => e.name)
            .toList();

        final newLoaders = console.chooseMultiple(
          loaders,
          "Select loaders",
          formatter: (entry) => entry.capitalized,
          selected: project.loaders,
          allowNone: false,
        );

        project.loaders
          ..clear()
          ..addAll(newLoaders);
      }),
      Option("Platform-specific project IDs", (project) async {
        final service = console.choose(
          UploadService.registered,
          "Choose platform",
          formatter: (entry) => entry.name,
          ephemeral: true,
        );

        final newId = await console.promptValidatedAsync(
          project.idByService.containsKey(service.id)
              ? "${service.name} project ID (blank to remove)"
              : "${service.name} project ID",
          (input) async => input.isNotEmpty && !await Spinner.wait("Validating...", service.isProject(input))
              ? "No project with ID '$input' was found"
              : null,
          allowOverride: true,
        );

        if (newId.isEmpty) {
          console.undoLine();
          print(
            c.warning("${service.name} project ID removed - ${project.displayName} will no longer be uploaded there"),
          );

          project.idByService.remove(service.id);
        } else {
          project.idByService[service.id] = newId;
        }
      }),
      Option("Relations", (project) async {
        final relation = console.choose(
          [...project.relations, _addRelationSentinel],
          "Choose relation",
          formatter: (entry) => !identical(entry, _addRelationSentinel) ? "Remove ${entry.name}" : entry.name,
          ephemeral: true,
        );

        if (identical(relation, _addRelationSentinel)) {
          final newRelationName = console.prompt("New relation name");
          final newRelationType =
              console.choose(ModrinthDependencyType.values, "New relation type", formatter: (entry) => entry.name);

          final idByService = <String, String>{};
          final services = [...UploadService.registered];
          while (services.isNotEmpty) {
            final service = services.length == 1
                ? services.single
                : console.choose(
                    services,
                    "Choose platform",
                    formatter: (entry) => entry.name,
                    ephemeral: true,
                  );

            idByService[service.id] = console.prompt("${service.name} dependency ID");

            services.remove(service);
            if (services.isNotEmpty && !console.ask("Add more", ephemeral: true)) break;
          }

          project.relations.add(Relation(newRelationName, newRelationType, idByService));
          print(c.success("New relation '$newRelationName' added"));
        } else {
          project.relations.remove(relation);
          print(c.warning("Relation '${relation.name} removed'"));
        }
      }),
      Option("Changelog file path", (project) {
        final newPath = console.prompt(
          project.changelogFilePath != null ? "New changelog file path (blank to remove)" : "Changelog file path",
        );

        if (newPath.isEmpty) {
          console.undoLine();
          print(c.warning("Changelog file path cleared"));

          project.changelogFilePath = null;
        } else {
          project.changelogFilePath = newPath;
        }
      }),
      Option("Primary file pattern", (project) {
        final newPattern = console.prompt(
          project.primaryFilePattern != null ? "New primary file pattern (blank to remove)" : "Primary file pattern",
        );

        if (newPattern.isEmpty) {
          console.undoLine();
          print(c.warning("Primary file pattern cleared"));

          project.primaryFilePattern = null;
        } else {
          project.primaryFilePattern = newPattern;
        }
      }),
    ];
