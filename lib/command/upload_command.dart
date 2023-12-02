import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:args/args.dart';
import 'package:dart_console/dart_console.dart';
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
import '../upload/upload_service.dart';
import 'synk_command.dart';

class UploadCommand extends SynkCommand {
  static const _retryArg = "retry";
  static const _dryRunArg = "dry-run";
  static const _confirmServicesArg = "confirm-services";
  static const _overrideVersionsArg = "override-game-versions";

  static const _lastUploadKey = "last_upload";

  static final _stableGameVersion = RegExp(r"^(\d+)\.(\d+)(\.(\d+))?$");

  final ConfigProvider _provider;
  final ProjectDatabase _db;
  final SynkConfig _config;
  final ModrinthApi _mr;
  final UploadServices _uploadServices;

  UploadCommand(this._provider, this._config, this._db, this._mr, this._uploadServices)
      : super(
          "upload",
          "Upload a new set of atifacts for the given project",
          arguments: const ["project-id"],
        ) {
    argParser
      ..addFlag(
        _retryArg,
        help: "Re-run the previous upload process (useful if one or more of the uploads failed)",
        negatable: false,
      )
      ..addFlag(
        _dryRunArg,
        help: "Run the upload process as normal but do not actually send any web requests",
        negatable: false,
      )
      ..addFlag(
        _confirmServicesArg,
        help: "Ask before uploading to each individual service",
        negatable: false,
      )
      ..addFlag(
        _overrideVersionsArg,
        help: "Override the game versions used during this specific upload process",
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

    if (args.wasParsed(_dryRunArg)) {
      print(c.warning("Doing a dry run, no upload requests will be sent"));
    }

    Map<String, bool>? previousUploadSuccess;
    UploadRequest request;

    if (!args.wasParsed(_retryArg)) {
      final newRequest = await _getRequestFromUser(args, project);
      if (newRequest == null) return;

      request = newRequest;
    } else {
      final previousLog = _provider.readConfigData(_lastUploadKey);
      if (previousLog == null) {
        print(c.error("You did not try to upload anything yet"));
        return;
      }

      request = UploadRequest.fromJson(previousLog["request"]);
      previousUploadSuccess = (previousLog["upload_succeeded"] as Map<String, dynamic>).cast();
    }

    console
      ..writeLine()
      ..writeLine("The following release will be created:")
      ..write((Table()
            ..insertRow(["Title", request.title])
            ..insertRow(["Version", request.version])
            ..insertRow(["Release Type", request.releaseType.color(request.releaseType.name)])
            ..insertRow(["Game Versions", request.compatibleGameVersions.join(", ")])
            ..insertRow(["Changelog", request.changelog.truncate(60)])
            ..insertRow([])
            ..insertRows(
              request.files.map((e) => ["", basename(e.path)]).toList()..[0][0] = "${request.files.length} Files",
            ))
          .render());

    if (!console.ask("Proceed with upload", ephemeral: true)) return;

    final uploadSucceeded = <String, bool>{};
    final log = {
      "request": request.toJson(),
      "upload_succeeded": uploadSucceeded,
    };

    if (previousUploadSuccess != null) {
      uploadSucceeded.addAll(previousUploadSuccess);

      for (final serviceId in project.idByService.keys) {
        final service = _uploadServices[serviceId]!;
        if (!previousUploadSuccess.containsKey(serviceId)) {
          print(c.hint("Uploading to ${service.name} was manually omitted previously, skipping"));
          continue;
        }

        if (previousUploadSuccess[serviceId]!) {
          print(c.hint("Uploading to ${service.name} succeeded previously, skipping"));
          continue;
        }

        _tryUpload(args.wasParsed(_dryRunArg), project, request, service, uploadSucceeded);
      }
    } else {
      for (final serviceId in project.idByService.keys) {
        final service = _uploadServices[serviceId]!;
        if (args.wasParsed(_confirmServicesArg) && !console.ask("Upload to ${service.name}")) {
          continue;
        }

        await _tryUpload(args.wasParsed(_dryRunArg), project, request, service, uploadSucceeded);
      }
    }

    _provider.saveConfigData(_lastUploadKey, log);
  }

  @override
  String get invocation => "${super.invocation} [<file(s)>]";

  Future<UploadRequest?> _getRequestFromUser(ArgResults args, Project project) async {
    String version;
    List<File> files;
    if (args.rest.length < 2 && project.primaryFilePattern == null) {
      print(c.error(
        "You must provide file(s) to upload, as there is no primary file pattern configured in project ${project.displayName}",
      ));
      print(c.hint("You can run 'synk edit ${project.projectId}' to add one"));
      return null;
    } else if (args.rest.length >= 2) {
      files = args.rest.skip(1).map((e) => File(e)).toList();
      for (var file in files) {
        if (file.existsSync()) continue;

        print(c.error("Could find file ${file.path}"));
        return null;
      }

      version = _askUserIfVersionUnknown(basename(files.first.path), await _tryReadVersion(project, files.first));
    } else {
      files = project.findPrimaryFiles()!.where((element) => !element.path.contains("sources")).toList();
      if (files.isEmpty) {
        print(c.error("Artifact discovery found nothing, you must manually provide file(s) as an argument"));
        print(c.hint(
          "Unless you actually have no artifacts ready, it's quite likely your primary file pattern is misconfigured. Run 'synk edit ${project.projectId}' to fix it",
        ));

        return null;
      }

      final versions = (await Future.wait(files.map((e) => _tryReadVersion(project, e).then((v) => (e, v))))).map((e) {
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

      files
        ..clear()
        ..add(chosen.$1)
        ..addAll(project.resolveSecondaryFiles(chosen.$1));
      version = _askUserIfVersionUnknown(basename(chosen.$1.path), chosen.$2);
    }

    _config.overlay = ConfigOverlay.ofProject(_db, project);

    final releaseType = console.choose(
      ReleaseType.values,
      "Release type",
      formatter: (entry) => entry.name,
    );

    var gameVersions = _config.minecraftVersions;
    if (gameVersions.isEmpty || args.wasParsed(_overrideVersionsArg)) {
      final versionList = (await Spinner.wait("Fetching versions", _mr.tags.getGameVersions()))
          .where((e) => e.versionType == ModrinthGameVersionType.release)
          .map((e) => e.version)
          .toList();

      gameVersions = console.chooseMultiple(versionList, "Select compatible Minecraft versions");
    }

    final parsedGameVersions = gameVersions.map(_tryParseVersion).whereType<Version>();

    var minGameVersion = parsedGameVersions.isNotEmpty
        ? parsedGameVersions.reduce((e1, e2) => e1 < e2 ? e1 : e2).toString()
        : parsedGameVersions.first.toString();
    if (minGameVersion.endsWith(".0")) minGameVersion = minGameVersion.substring(0, minGameVersion.length - 2);
    if (parsedGameVersions.length > 1) minGameVersion += "+";

    final parsedVersion = _tryParseVersion(version);
    final processedVersion =
        parsedVersion != null ? "${parsedVersion.major}.${parsedVersion.minor}.${parsedVersion.patch}" : version;

    final changelog = await _config.changelogReader.getChangelog(project);
    final title = _config.versionNamePattern
        .replaceAll("{project_name}", project.displayName)
        .replaceAll("{version}", processedVersion)
        .replaceAll("{game_version}", minGameVersion);

    return UploadRequest(title, version, changelog, releaseType, gameVersions, project.relations, files);
  }

  /// Try to read the version of the given artifact according to the
  /// metadata formats prescribed by different loaders / modpack formats
  ///
  /// Currently supported are:
  ///  - Forge mods
  ///  - Fabric mods
  ///  - Quilt mods
  ///  - .mrpack modpacks
  Future<String?> _tryReadVersion(Project project, File file) async {
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

  String _askUserIfVersionUnknown(String filename, String? maybeVersion) {
    if (maybeVersion == null) {
      print(c.warning("The version of file '$filename' could not be determined"));
      return console.prompt("Enter version");
    } else {
      return maybeVersion;
    }
  }

  /// Try to interpret [versionString] as a semantic version. This method first tries
  /// to do this via [Version.parse] - if that fails, it tries to extract at least a
  /// major and minor version (optionally a patch), omitting build and prerelease.
  ///
  /// If both of these approaches fail, [null] is returned
  Version? _tryParseVersion(String versionString) {
    try {
      return Version.parse(versionString);
    } catch (_) {
      final match = _stableGameVersion.firstMatch(versionString);
      if (match == null) return null;

      return Version(int.parse(match[1]!), int.parse(match[2]!), match[3] != null ? int.parse(match[3]!) : 0);
    }
  }

  /// Try to submit [request] for [project] to [service]. If [dryRun] is `true`,
  /// do not actually call [UploadService.upload] - instead, always assume success.
  ///
  /// If the request succeeds, the resulting release URI is logged and `true`
  /// is stored under [service]'s id in [sucesssRecord]
  ///
  /// IF the request fails, a warning with the causing error is logged and `false`
  /// is stored under [service]'s id in [sucesssRecord]
  Future<void> _tryUpload(
    bool dryRun,
    Project project,
    UploadRequest request,
    UploadService service,
    Map<String, bool> sucesssRecord,
  ) async {
    print("Uploading to ${service.name}...");

    try {
      Uri? uploadedFile;
      if (!dryRun) {
        uploadedFile = await service.upload(project, request);
      }

      console
        ..undoLine()
        ..writeLine(
          c.success("Uploaded to ${service.name} (${uploadedFile ?? "A link to the created release would go here"})"),
        );
      sucesssRecord[service.id] = true;
    } on UploadException catch (e) {
      print(c.error("Uploading to ${service.name} failed: ${e.message}"));
      sucesssRecord[service.id] = false;
    }
  }
}

extension on ArchiveFile {
  String get contentString => utf8.decode(content as List<int>);
}
