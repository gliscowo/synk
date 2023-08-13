// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curseforge_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$CurseForgeUploadPayloadToJson(
    _CurseForgeUploadPayload instance) {
  final val = <String, dynamic>{
    'changelog': instance.changelog,
    'changelogType': _$_CurseForgeChangelogTypeEnumMap[instance.changelogType]!,
    'releaseType': _$ReleaseTypeEnumMap[instance.releaseType]!,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('gameVersions', instance.gameVersions);
  writeNotNull('displayName', instance.displayName);
  writeNotNull('parentFileID', instance.parentFileID);
  writeNotNull('relations',
      _CurseForgeUploadPayload._relationsToJson(instance.relations));
  return val;
}

const _$_CurseForgeChangelogTypeEnumMap = {
  _CurseForgeChangelogType.text: 'text',
  _CurseForgeChangelogType.html: 'html',
  _CurseForgeChangelogType.markdown: 'markdown',
};

const _$ReleaseTypeEnumMap = {
  ReleaseType.release: 'release',
  ReleaseType.beta: 'beta',
  ReleaseType.alpha: 'alpha',
};

Map<String, dynamic> _$CurseForgeRelationToJson(_CurseForgeRelation instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'type': _$_CurseForgeRelationTypeEnumMap[instance.type]!,
    };

const _$_CurseForgeRelationTypeEnumMap = {
  _CurseForgeRelationType.embeddedLibrary: 'embeddedLibrary',
  _CurseForgeRelationType.incompatible: 'incompatible',
  _CurseForgeRelationType.optionalDependency: 'optionalDependency',
  _CurseForgeRelationType.requiredDependency: 'requiredDependency',
  _CurseForgeRelationType.tool: 'tool',
};
