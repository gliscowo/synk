import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:args/args.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:path/path.dart';
import 'package:synk/config/types.dart';
import 'package:toml/toml.dart';

import '../config/config.dart';
import '../config/database.dart';
import '../terminal/ansi.dart' as c;
import '../terminal/console.dart';
import '../terminal/spinner.dart';
import '../upload/types.dart';
import 'synk_command.dart';

class UploadCommand extends SynkCommand {
  final ProjectDatabase _db;
  final SynkConfig _config;
  final ModrinthApi _mr;

  UploadCommand(this._config, this._db, this._mr)
      : super(
          "upload",
          "Upload a new set of atifacts for the given project",
          arguments: ["project-id"],
        ) {
    argParser
      ..addFlag(
        "retry",
        help: "Re-run the previous upload process (useful if one or more of the uploads failed)",
        negatable: false,
      )
      ..addFlag(
        "dry-run",
        help: "Run the upload process as normal but do not actually send any web requests",
        negatable: false,
      );
  }

  @override
  FutureOr<void> execute(ArgResults args) async {
    final project = _db[args.rest.first];
    if (project == null) {
      print(c.error("No project with id '${args.rest.first}' found in database"));
      print(c.hint("You may want to run 'synk create' to add it, or import using 'synk import' if it already exists"));

      return;
    }

    List<File> files;
    if (args.rest.length < 2 && project.primaryFilePattern == null) {
      print(c.error(
        "You must provide file(s) to upload, as there is no primary file pattern configured in project ${project.displayName}",
      ));
      print(c.hint("You can run 'synk edit ${project.projectId}' to add one"));
      return;
    } else if (args.rest.length > 2) {
      files = args.rest.skip(1).map((e) => File(e)).toList();
      for (var file in files) {
        if (file.existsSync()) continue;

        print(c.error("Could find file ${file.path}"));
        return;
      }
    } else {
      files = project.findPrimaryFiles()!.where((element) => !element.path.contains("sources")).toList();
      final versions = (await Future.wait(files.map((e) => tryExtractVersion(project, e)))).toList();

      final chosen = console.choose(
        files,
        "Choose version",
        formatter: (entry) => versions[files.indexOf(entry)] ?? basename(entry.path),
      );

      files.addAll(project.resolveSecondaryFiles(chosen));
    }

    _config.overlay = ConfigOverlay.ofProject(_db, project);

    final releaseType = console.choose(
      ReleaseType.values,
      "Release type",
      formatter: (entry) => entry.name,
    );

    var gameVersions = _config.minecraftVersions;
    if (gameVersions.isEmpty) {
      final versionList = (await Spinner.wait("Fetching versions", _mr.tags.getGameVersions()))
          .where((e) => e.versionType == ModrinthGameVersionType.release)
          .map((e) => e.version)
          .toList();

      gameVersions = console.chooseMultiple(versionList, "Select compatible Minecraft versions");
    }

    final changelog = await _config.changelogReader.getChangelog(project);

    // final request = UploadRequest(title, version, changelog, releaseType, gameVersions, project.relations, files);
  }

  @override
  String get invocation => "${super.invocation} [<file(s)>]";
}

Future<String?> tryExtractVersion(Project project, File file) async {
  Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(await file.readAsBytes());
  } catch (_) {
    return null;
  }

  final ext = extension(file.path);
  if (project.type == ModrinthProjectType.mod && ext == ".jar") {
    final fmj = archive.findFile("fabric.mod.json");
    if (fmj != null && (project.loaders.contains("fabric") || project.loaders.contains("quilt"))) {
      if (jsonDecode(fmj.contentString) case {"version": String version}) {
        return version;
      }
    }

    final qmj = archive.findFile("quilt.mod.json");
    if (qmj != null && project.loaders.contains("quilt")) {
      if (jsonDecode(qmj.contentString) case {"quilt_loader": {"version": String version}}) {
        return version;
      }
    }

    final modsToml = archive.findFile("META-INF/mods.toml");
    if (modsToml != null && (project.loaders.contains("forge") || project.loaders.contains("neoforge"))) {
      if (TomlDocument.parse(modsToml.contentString).toMap() case {"mods": [{"version": String version}, ...]}) {
        return version;
      }
    }
  } else if (project.type == ModrinthProjectType.modpack && ext == ".mrpack") {
    final index = archive.findFile("modrinth.index.json");
    if (index != null) {
      if (jsonDecode(index.contentString) case {"versionId": String version}) {
        return version;
      }
    }
  }

  return null;
}

extension on ArchiveFile {
  String get contentString => utf8.decode(content as List<int>);
}
