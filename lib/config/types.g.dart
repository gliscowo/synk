// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project._(
      $enumDecode(_$ModrinthProjectTypeEnumMap, json['type']),
      json['display_name'] as String,
      json['project_id'] as String,
      (json['minecraft_versions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      (json['loaders'] as List<dynamic>).map((e) => e as String).toList(),
      json['config_overlay'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
      'type': _$ModrinthProjectTypeEnumMap[instance.type]!,
      'display_name': instance.displayName,
      'project_id': instance.projectId,
      'minecraft_versions': instance.minecraftVersions,
      'loaders': instance.loaders,
      'config_overlay': instance.configOverlay,
    };

const _$ModrinthProjectTypeEnumMap = {
  ModrinthProjectType.mod: 'mod',
  ModrinthProjectType.modpack: 'modpack',
  ModrinthProjectType.resourcepack: 'resourcepack',
  ModrinthProjectType.shader: 'shader',
};

ConfigData _$ConfigDataFromJson(Map<String, dynamic> json) => ConfigData(
      (json['default_minecraft_versions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ConfigDataToJson(ConfigData instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('default_minecraft_versions', instance.defaultMinecraftVersions);
  return val;
}
