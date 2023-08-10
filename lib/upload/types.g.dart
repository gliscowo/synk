// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadRequest _$UploadRequestFromJson(Map<String, dynamic> json) =>
    UploadRequest(
      json['title'] as String,
      json['version'] as String,
      json['changelog'] as String,
      $enumDecode(_$ReleaseTypeEnumMap, json['release_type']),
      (json['compatible_game_versions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      (json['relations'] as List<dynamic>)
          .map((e) => Relation.fromJson(e as Map<String, dynamic>))
          .toList(),
      UploadRequest._filesFromJson(json['files'] as List<String>),
    );

Map<String, dynamic> _$UploadRequestToJson(UploadRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'version': instance.version,
      'changelog': instance.changelog,
      'release_type': _$ReleaseTypeEnumMap[instance.releaseType]!,
      'compatible_game_versions': instance.compatibleGameVersions,
      'relations': instance.relations,
      'files': UploadRequest._filesToJson(instance.files),
    };

const _$ReleaseTypeEnumMap = {
  ReleaseType.release: 'release',
  ReleaseType.beta: 'beta',
  ReleaseType.alpha: 'alpha',
};

Relation _$RelationFromJson(Map<String, dynamic> json) => Relation(
      $enumDecode(_$ModrinthDependencyTypeEnumMap, json['type']),
      Map<String, String>.from(json['project_id_by_platform'] as Map),
    );

Map<String, dynamic> _$RelationToJson(Relation instance) => <String, dynamic>{
      'type': _$ModrinthDependencyTypeEnumMap[instance.type]!,
      'project_id_by_platform': instance.projectIdByPlatform,
    };

const _$ModrinthDependencyTypeEnumMap = {
  ModrinthDependencyType.required: 'required',
  ModrinthDependencyType.optional: 'optional',
  ModrinthDependencyType.incompatible: 'incompatible',
  ModrinthDependencyType.embedded: 'embedded',
};
