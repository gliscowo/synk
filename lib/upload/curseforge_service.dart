import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:modrinth_api/modrinth_api.dart';

import '../config/tokens.dart';
import '../config/types.dart';
import '../terminal/console.dart';
import 'types.dart';
import 'upload_service.dart';

part 'curseforge_service.g.dart';

class CurseForgeUploadService implements UploadService {
  static const String _baseUrl = "https://minecraft.curseforge.com/api";
  static final RegExp _snapshot = RegExp("([0-9]{2}w[0-9]{2}[a-z])|(.+-(pre|rc)[0-9])");

  @override
  final String id = "curseforge";

  @override
  final String name = "CurseForge";

  final Client _client;
  final TokenStore _tokens;

  CurseForgeUploadService(this._client, this._tokens);

  @override
  Future<bool> isProject(String projectId) => _client
      .get(Uri.parse("$_baseUrl/projects/$projectId/localization/export"), headers: _headers)
      .then((value) => value.statusCode == 403);

  @override
  bool supportsProjectType(ModrinthProjectType type) => true;

  @override
  Future<String?> testAuth() async {
    if (_tokens[id] == null) return "Missing token";

    return _client
        .get(Uri.parse("$_baseUrl/game/versions"), headers: _headers)
        .then((value) => value.statusCode == 200 ? null : jsonDecode(value.body)["errorMessage"] as String);
  }

  @override
  Future<Uri> upload(Project project, UploadRequest request) async {
    // TODO maybe support other changelog types here
    final changelogType = _CurseForgeChangelogType.markdown;
    final relations =
        request.relations.map((e) => _CurseForgeRelation(e.projectIdByPlatform[id]!, e.type.toCurseForge())).toList();

    final parentUploadResponse = await _uploadFile(
      project,
      _CurseForgeUploadPayload(
        request.changelog,
        changelogType,
        request.releaseType,
        gameVersions: await _mapVersions(request.compatibleGameVersions),
        displayName: request.title,
        relations: relations,
      ),
      request.files.first,
    );

    if (parentUploadResponse.statusCode != 200) {
      throw UploadException(jsonDecode(parentUploadResponse.body)["errorMessage"]);
    }

    int parentFileId = jsonDecode(parentUploadResponse.body)["id"] as int;
    for (var subFile in request.files.skip(1)) {
      final subFileResponse = await _uploadFile(
        project,
        _CurseForgeUploadPayload(
          request.changelog,
          changelogType,
          request.releaseType,
          parentFileID: parentFileId,
          relations: relations,
        ),
        subFile,
      );

      if (subFileResponse.statusCode != 200) {
        throw UploadException(jsonDecode(subFileResponse.body)["errorMessage"]);
      }
    }

    return Uri.parse("https://curseforge.com/minecraft/mc-mods/${project.idByService[id]}/files/$parentFileId");
  }

  Future<Response> _uploadFile(Project project, _CurseForgeUploadPayload payload, File file) async {
    final request = MultipartRequest("POST", Uri.parse("$_baseUrl/projects/${project.idByService[id]!}/upload-file"))
      ..fields["metadata"] = jsonEncode(payload.toJson())
      ..files
          .add(await MultipartFile.fromPath("file", file.path, contentType: MediaType("application", "java-archive")));

    return _client.send(request).then(Response.fromStream);
  }

  /// Translate the given set of Minecraft version names to
  /// their CurseForge ID counterparts.
  ///
  /// The algorithm used for interpreting the mappings handed
  /// out by the API is as follows:
  /// 1. Remove any mappings with a type of 3 (which are FML versions), 615
  /// (which could be Bedrock versions?) and 73247 (which are Fabric Loader)
  /// 2. Sort the remaining versions by their `gameVersionTypeId`,
  /// in reverse natural order
  /// 3. For each element of [minecraftVersions], pick the first mapping
  /// where the `name` field equals the element *or* ask the user to provide
  /// the CurseForge equivalent if no such mapping exists (like for snapshot releases)
  Future<List<int>> _mapVersions(List<String> minecraftVersions) async {
    final response = await _client.get(
      Uri.parse("$_baseUrl/game/versions"),
      headers: _headers,
    );

    final cfVersionList = (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((element) =>
            element["gameVersionTypeID"] != 3 /* forge */ &&
            element["gameVersionTypeID"] != 73247 /* fabric */ &&
            element["gameVersionTypeID"] != 615 /* bedrock? */)
        .toList()
      ..sort((a, b) => -(a["gameVersionTypeID"] as int).compareTo(b["gameVersionTypeID"] as int));

    return minecraftVersions.map((e) {
      do {
        if (_snapshot.hasMatch(e)) {
          e = "${console.prompt("Release version equivalent for snapshot $e")}-Snapshot";
        }

        for (var mapping in cfVersionList) {
          if (mapping["name"] == e) return mapping["id"] as int;
        }

        e = console.prompt("CurseForge equivalent of snapshot version $e");
      } while (true);
    }).toList();
  }

  Map<String, String> get _headers => {"x-api-token": _tokens[id] ?? ""};
}

extension on ModrinthDependencyType {
  _CurseForgeRelationType toCurseForge() => switch (this) {
        ModrinthDependencyType.required => _CurseForgeRelationType.requiredDependency,
        ModrinthDependencyType.optional => _CurseForgeRelationType.optionalDependency,
        ModrinthDependencyType.embedded => _CurseForgeRelationType.embeddedLibrary,
        ModrinthDependencyType.incompatible => _CurseForgeRelationType.incompatible
      };
}

// --- request payload types ---

@JsonSerializable(createFactory: false, includeIfNull: false)
class _CurseForgeUploadPayload {
  final String changelog;
  final _CurseForgeChangelogType changelogType;
  final ReleaseType releaseType;

  final List<int>? gameVersions;
  final String? displayName;
  final int? parentFileID;
  @JsonKey(toJson: _relationsToJson)
  final List<_CurseForgeRelation>? relations;

  _CurseForgeUploadPayload(
    this.changelog,
    this.changelogType,
    this.releaseType, {
    this.gameVersions,
    this.displayName,
    this.parentFileID,
    this.relations,
  });

  Map<String, dynamic> toJson() => _$CurseForgeUploadPayloadToJson(this);

  static Map<String, dynamic>? _relationsToJson(List<_CurseForgeRelation>? relations) =>
      relations != null ? {"projects": relations.map(_$CurseForgeRelationToJson).toList()} : null;
}

enum _CurseForgeChangelogType {
  text,
  html,
  markdown,
}

@JsonSerializable(createFactory: false)
class _CurseForgeRelation {
  final String slug;
  final _CurseForgeRelationType type;

  _CurseForgeRelation(this.slug, this.type);
}

enum _CurseForgeRelationType {
  embeddedLibrary,
  incompatible,
  optionalDependency,
  requiredDependency,
  tool,
}
