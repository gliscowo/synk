import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:path/path.dart';

import '../terminal/console.dart';
import '../upload/upload_request.dart';

part 'project.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, constructor: "_json")
class Project {
  ModrinthProjectType type;
  String displayName;
  String projectId;
  final List<String> loaders;
  final List<Relation> relations;
  final Map<String, String> idByService;

  String? changelogFilePath;
  String? primaryFilePattern;
  final Map<String, String> secondaryFilePatterns;

  Map<String, dynamic> configOverlay;

  Project._json(
    this.type,
    this.displayName,
    this.projectId,
    this.loaders,
    this.relations,
    this.idByService,
    this.changelogFilePath,
    this.configOverlay,
    this.secondaryFilePatterns,
  );

  Project(
    this.type,
    this.displayName,
    this.projectId,
    this.loaders,
    this.relations,
    this.idByService,
    this.changelogFilePath,
    this.primaryFilePattern,
    this.secondaryFilePatterns,
  ) : configOverlay = {};

  /// Find all files matched by this project's [primaryFilePattern]
  ///
  /// If no such pattern is defined, return `null`
  Iterable<File>? findPrimaryFiles() {
    if (primaryFilePattern == null) return null;
    return Glob(primaryFilePattern!).listSync().whereType<File>();
  }

  /// Resolve the secondary files related to this [primaryFile]
  /// as specified by this project's [secondaryFilePatterns]
  ///
  /// Such a pattern may use the `{name}` and `{ext}` placeholders
  /// to refer to the filename without extension and the extension of
  /// [primaryFile] respectively
  Iterable<File> resolveSecondaryFiles(File primaryFile) {
    final primaryFileName = basenameWithoutExtension(primaryFile.path);
    final primaryFileExtension = extension(primaryFile.path).substring(1);

    return secondaryFilePatterns.values.map((value) {
      var path = value.replaceAll("{name}", primaryFileName).replaceAll("{ext}", primaryFileExtension);
      if (!isAbsolute(path)) path = join(primaryFile.parent.path, path);

      return File(canonicalize(path));
    }).where((element) => element.existsSync());
  }

  String get formatted => (Table()
        ..title = "${type.name.capitalized} - $displayName"
        ..insertRows([
          ["Project ID", projectId],
          [],
          ["Loaders", loaders.join(", ")],
          if (primaryFilePattern != null) ["Primary files", primaryFilePattern!],
          [],
          for (var MapEntry(:key, :value) in idByService.entries) ["$key id", value],
          if (relations.isNotEmpty) ...[
            [],
            ["Relations"],
            [],
            for (var Relation(:name, :type, :projectIdByPlatform) in relations) ...[
              [name, type.name],
              for (var MapEntry(:key, :value) in projectIdByPlatform.entries) ["  $key", "  $value"]
            ]
          ],
        ]))
      .render();

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}
