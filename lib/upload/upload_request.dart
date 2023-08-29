import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:modrinth_api/modrinth_api.dart';

import '../terminal/ansi.dart' as c;
import '../terminal/console.dart';

part 'upload_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UploadRequest {
  final String title;
  final String version;
  final String changelog;
  final ReleaseType releaseType;

  final List<String> compatibleGameVersions;
  final List<Relation> relations;

  @JsonKey(toJson: _filesToJson, fromJson: _filesFromJson)
  final List<File> files;

  UploadRequest(
    this.title,
    this.version,
    this.changelog,
    this.releaseType,
    this.compatibleGameVersions,
    this.relations,
    this.files,
  ) {
    if (files.isEmpty) throw ArgumentError("At least on file must be provided", "files");
  }

  factory UploadRequest.fromJson(Map<String, dynamic> json) => _$UploadRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UploadRequestToJson(this);

  static List<String> _filesToJson(List<File> files) => files.map((e) => e.path).toList();
  static List<File> _filesFromJson(List<String> files) => files.map((e) => File(e)).toList();
}

enum ReleaseType implements Formattable {
  release(c.green),
  beta(c.yellow),
  alpha(c.red);

  @override
  final c.AnsiControlSequence color;
  const ReleaseType(this.color);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Relation {
  final String name;
  final ModrinthDependencyType type;
  final Map<String, String> projectIdByPlatform;

  Relation(this.name, this.type, this.projectIdByPlatform);

  factory Relation.fromJson(Map<String, dynamic> json) => _$RelationFromJson(json);
  Map<String, dynamic> toJson() => _$RelationToJson(this);
}
