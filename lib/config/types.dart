import 'package:dart_console/dart_console.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:synk/terminal/changelog_reader.dart';
import 'package:synk/terminal/console.dart';

part 'types.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, constructor: "_json")
class Project {
  ModrinthProjectType type;
  String displayName;
  String projectId;
  String? changelogFilePath;
  final List<String> loaders;
  final Map<String, String> idByService;

  Map<String, dynamic> configOverlay;

  Project._json(
    this.type,
    this.displayName,
    this.projectId,
    this.changelogFilePath,
    this.loaders,
    this.idByService,
    this.configOverlay,
  );

  Project(
    this.type,
    this.displayName,
    this.projectId,
    this.loaders,
    this.idByService, {
    this.changelogFilePath,
  }) : configOverlay = {};

  String get formatted => (Table()
        ..title = "${type.name.capitalized} - $displayName"
        ..insertRows([
          ["Project ID", projectId],
          [],
          ["Loaders", loaders.join(", ")]
        ]))
      .render();

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ConfigData {
  static const defaultValues = ConfigData(null, null);

  final List<String>? defaultMinecraftVersions;
  final ChangelogReader? changelogReader;

  const ConfigData(this.defaultMinecraftVersions, this.changelogReader);

  factory ConfigData.fromJson(Map<String, dynamic> json) => _$ConfigDataFromJson(json);
  Map<String, dynamic> toJson() => _$ConfigDataToJson(this);
}
