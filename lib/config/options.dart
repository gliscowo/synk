import 'dart:async';

import 'package:modrinth_api/modrinth_api.dart';

import '../terminal/ansi.dart' as c;
import '../terminal/changelog_reader.dart';
import '../terminal/console.dart';
import '../terminal/spinner.dart';
import '../upload/upload_request.dart';
import '../upload/upload_service.dart';
import 'config.dart';
import 'project.dart';

final _addRelationSentinel = Relation("Add new relation", ModrinthDependencyType.required, const {});
final _addSecondaryFilePatternSentinel = "_synk_add_new_pattern";

class Option<H> {
  /// The name of this option to be displayed
  /// to the use in menus
  final String name;
  final FutureOr<void> Function(H) _updateFunc;

  Option(this.name, this._updateFunc);

  /// Ask the user to update the stored
  /// value of this option
  FutureOr<void> update(H holder) => _updateFunc(holder);
}

List<Option<SynkConfig>> createConfigOptions(ModrinthApi mr) => [
      Option("Changelog reader", (config) {
        config.changelogReader = console.choose<ChangelogReader>(
          ChangelogReader.values,
          "Default changelog reader",
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

List<Option<Project>> createProjectOptions(UploadServices uploadServices, ModrinthApi mr) => [
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
          uploadServices.all,
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
          print(c.warning(
            "${service.name} project ID removed - ${project.displayName} will no longer be uploaded there",
          ));

          project.idByService.remove(service.id);
        } else {
          project.idByService[service.id] = newId;
        }
      }),
      Option("Add/remove relations", (project) async {
        final relation = project.relations.isNotEmpty
            ? console.choose(
                [...project.relations, _addRelationSentinel],
                "Choose option",
                formatter: (entry) => !identical(entry, _addRelationSentinel) ? "Remove ${entry.name}" : entry.name,
                ephemeral: true,
              )
            : null;

        if (relation == null || identical(relation, _addRelationSentinel)) {
          if (relation == null) {
            print(c.hint("${project.displayName} has no relations, adding a new one"));
          }

          final relationName = console.prompt("Relation name");
          final relationType = console.choose(
            ModrinthDependencyType.values,
            "Relation type",
            formatter: (entry) => entry.name,
          );

          final idByService = <String, String>{};
          final services = [...uploadServices.all];
          do {
            final service = services.singleOrNull ??
                console.choose<UploadService>(
                  services,
                  "Choose platform",
                  formatter: (entry) => entry.name,
                  ephemeral: true,
                );

            idByService[service.id] = console.prompt("${service.name} dependency ID");
            services.remove(service);
          } while (services.isNotEmpty && console.ask("Add more"));

          project.relations.add(Relation(relationName, relationType, idByService));
          print(c.success("New relation '$relationName' added"));
        } else {
          project.relations.remove(relation);
          print(c.warning("Relation '${relation.name}' removed"));
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
      Option("Add/remove secondary file patterns", (project) {
        final patternId = project.secondaryFilePatterns.isNotEmpty
            ? console.choose(
                [...project.secondaryFilePatterns.keys, _addSecondaryFilePatternSentinel],
                "Choose option",
                formatter: (entry) =>
                    !identical(entry, _addSecondaryFilePatternSentinel) ? "Remove '$entry'" : "Add new pattern",
                ephemeral: true,
              )
            : null;

        if (patternId == null || identical(patternId, _addSecondaryFilePatternSentinel)) {
          if (patternId == null) {
            print(c.hint("${project.displayName} has no secondary file patterns, adding a new one"));
          }

          final newPatternId = console.prompt("Pattern ID");
          final newPattern = console.prompt("Pattern");

          project.secondaryFilePatterns[newPatternId] = newPattern;
          print(c.success("New secondary file pattern '$newPatternId' added"));
        } else {
          project.secondaryFilePatterns.remove(patternId);
          print(c.warning("Secondary file pattern '$patternId' removed"));
        }
      }),
    ];
