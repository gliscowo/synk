import 'package:dart_console/dart_console.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:synk/terminal/console.dart';

part 'types.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, constructor: "_")
class Project {
  ModrinthProjectType type;
  String displayName;
  String projectId;
  final List<String> minecraftVersions;
  final List<String> loaders;
  Map<String, dynamic> configOverlay;

  Project._(this.type, this.displayName, this.projectId, this.minecraftVersions, this.loaders, this.configOverlay);
  Project(this.type, this.displayName, this.projectId, this.minecraftVersions, this.loaders) : configOverlay = {};

  String get formatted => (Table()
        ..title = "${type.name.capitalized} - $displayName"
        ..insertRows([
          ["Project ID", projectId],
          [],
          ["Minecraft Versions", minecraftVersions.join(", ")],
          ["Loaders", loaders.join(", ")]
        ]))
      .render();

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ConfigData {
  static const defaultValues = ConfigData(null);

  final List<String>? defaultMinecraftVersions;
  const ConfigData(this.defaultMinecraftVersions);

  factory ConfigData.fromJson(Map<String, dynamic> json) => _$ConfigDataFromJson(json);
  Map<String, dynamic> toJson() => _$ConfigDataToJson(this);
}
