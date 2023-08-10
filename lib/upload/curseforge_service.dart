import 'dart:convert';

import 'package:http/http.dart';
import 'package:modrinth_api/modrinth_api.dart';

import '../config/tokens.dart';
import '../config/types.dart';
import 'types.dart';
import 'upload_service.dart';

class CurseForgeUploadService implements UploadService {
  static const String _url = "https://minecraft.curseforge.com";

  @override
  final String id = "curseforge";

  final Client _client;
  final TokenStore _tokens;

  CurseForgeUploadService(this._client, this._tokens);

  @override
  Future<bool> isProject(String projectId) => _client
      .get(Uri.parse("$_url/api/projects/$projectId/localization/export"), headers: _headers)
      .then((value) => value.statusCode == 403);

  @override
  bool supportsProjectType(ModrinthProjectType type) => true;

  @override
  Future<String?> testAuth() => _client
      .get(Uri.parse("$_url/api/game/versions"), headers: _headers)
      .then((value) => value.statusCode == 200 ? null : jsonDecode(value.body)["errorMessage"] as String);

  @override
  Future<Uri> upload(Project project, UploadRequest request) {
    // TODO: implement upload
    throw UnimplementedError();
  }

  Map<String, String> get _headers => {"x-api-token": _tokens[id] ?? ""};
}
