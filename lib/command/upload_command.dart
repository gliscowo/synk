import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:args/args.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:toml/toml.dart';

import '../config/config.dart';
import '../config/database.dart';
import '../config/project.dart';
import '../terminal/ansi.dart' as c;
import '../terminal/console.dart';
import '../terminal/spinner.dart';
import '../upload/upload_request.dart';
import 'synk_command.dart';

class UploadCommand extends SynkCommand {
  final ProjectDatabase _db;
  final SynkConfig _config;
  final ModrinthApi _mr;

  UploadCommand(this._config, this._db, this._mr)
      : super(
          "upload",
          "Upload a new set of atifacts for the given project",
          arguments: const ["project-id"],
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

    String version;
    List<File> files;
    if (args.rest.length < 2 && project.primaryFilePattern == null) {
      print(c.error(
        "You must provide file(s) to upload, as there is no primary file pattern configured in project ${project.displayName}",
      ));
      print(c.hint("You can run 'synk edit ${project.projectId}' to add one"));
      return;
    } else if (args.rest.length >= 2) {
      files = args.rest.skip(1).map((e) => File(e)).toList();
      for (var file in files) {
        if (file.existsSync()) continue;

        print(c.error("Could find file ${file.path}"));
        return;
      }

      version = askUserIfVersionUnknown(basename(files.first.path), await tryReadVersion(project, files.first));
    } else {
      files = project.findPrimaryFiles()!.where((element) => !element.path.contains("sources")).toList();
      final versions = (await Future.wait(files.map((e) => tryReadVersion(project, e).then((v) => (e, v))))).map((e) {
        var version = Version.none;
        if (e.$2 != null) {
          try {
            version = Version.parse(e.$2!);
          } on FormatException catch (_) {}
        }

        return (e.$1, e.$2, version);
      }).toList();

      final chosen = console.choose(
        versions..sort((a, b) => -a.$3.compareTo(b.$3)),
        "Choose version",
        formatter: (entry) => entry.$2 != null
            ? "${entry.$2?.padRight(30)} ${c.brightBlack("(${basename(entry.$1.path)})")}"
            : basename(entry.$1.path),
        resultFormatter: (entry) => entry.$2 ?? basename(entry.$1.path),
      );

      files.addAll(project.resolveSecondaryFiles(chosen.$1));
      version = askUserIfVersionUnknown(basename(chosen.$1.path), chosen.$2);
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

  /// Try to read the version of the given artifact according to the
  /// metadata formats prescribed by different loaders / modpack formats
  ///
  /// Currently supported are:
  ///  - Forge mods
  ///  - Fabric mods
  ///  - Quilt mods
  ///  - .mrpack modpacks
  Future<String?> tryReadVersion(Project project, File file) async {
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

  String askUserIfVersionUnknown(String filename, String? maybeVersion) {
    if (maybeVersion == null) {
      print(c.warning("The version of file '$filename' could not be determined"));
      return console.prompt("Enter version");
    } else {
      return maybeVersion;
    }
  }
}

extension on ArchiveFile {
  String get contentString => utf8.decode(content as List<int>);
}