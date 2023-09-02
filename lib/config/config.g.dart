// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigData _$ConfigDataFromJson(Map<String, dynamic> json) => ConfigData(
      (json['default_minecraft_versions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      $enumDecodeNullable(_$ChangelogReaderEnumMap, json['changelog_reader']),
      json['setup_completed'] as bool,
    );

Map<String, dynamic> _$ConfigDataToJson(ConfigData instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('default_minecraft_versions', instance.defaultMinecraftVersions);
  writeNotNull(
      'changelog_reader', _$ChangelogReaderEnumMap[instance.changelogReader]);
  val['setup_completed'] = instance.setupCompleted;
  return val;
}

const _$ChangelogReaderEnumMap = {
  ChangelogReader.editor: 'editor',
  ChangelogReader.prompt: 'prompt',
  ChangelogReader.file: 'file',
};
