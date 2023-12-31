// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project._json(
      $enumDecode(_$ModrinthProjectTypeEnumMap, json['type']),
      json['display_name'] as String,
      json['project_id'] as String,
      (json['loaders'] as List<dynamic>).map((e) => e as String).toList(),
      (json['relations'] as List<dynamic>)
          .map((e) => Relation.fromJson(e as Map<String, dynamic>))
          .toList(),
      Map<String, String>.from(json['id_by_service'] as Map),
      json['changelog_file_path'] as String?,
      json['config_overlay'] as Map<String, dynamic>,
      Map<String, String>.from(json['secondary_file_patterns'] as Map),
    )..primaryFilePattern = json['primary_file_pattern'] as String?;

Map<String, dynamic> _$ProjectToJson(Project instance) {
  final val = <String, dynamic>{
    'type': _$ModrinthProjectTypeEnumMap[instance.type]!,
    'display_name': instance.displayName,
    'project_id': instance.projectId,
    'loaders': instance.loaders,
    'relations': instance.relations,
    'id_by_service': instance.idByService,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('changelog_file_path', instance.changelogFilePath);
  writeNotNull('primary_file_pattern', instance.primaryFilePattern);
  val['secondary_file_patterns'] = instance.secondaryFilePatterns;
  val['config_overlay'] = instance.configOverlay;
  return val;
}

const _$ModrinthProjectTypeEnumMap = {
  ModrinthProjectType.mod: 'mod',
  ModrinthProjectType.modpack: 'modpack',
  ModrinthProjectType.resourcepack: 'resourcepack',
  ModrinthProjectType.shader: 'shader',
};
