// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mod _$ModFromJson(Map<String, dynamic> json) => Mod(
      json['display_name'] as String,
      json['mod_id'] as String,
      (json['minecraft_versions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      (json['loaders'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ModToJson(Mod instance) => <String, dynamic>{
      'display_name': instance.displayName,
      'mod_id': instance.modId,
      'minecraft_versions': instance.minecraftVersions,
      'loaders': instance.loaders,
    };
