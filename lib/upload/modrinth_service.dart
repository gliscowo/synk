import 'dart:async';

import 'package:modrinth_api/modrinth_api.dart';
import 'package:path/path.dart';

import '../config/project.dart';
import '../config/tokens.dart';
import 'upload_request.dart';
import 'upload_service.dart';

class ModrinthUploadService implements UploadService {
  @override
  final String id = "modrinth";
  @override
  final String name = "Modrinth";
  @override
  final bool supportsRelations = true;

  final ModrinthApi _mr;
  final TokenStore _tokens;

  ModrinthUploadService(this._mr, this._tokens);

  @override
  Future<bool> isProject(String projectId) async => await _mr.projects.get(projectId) != null;

  @override
  bool supportsProjectType(ModrinthProjectType type) => true;

  @override
  Future<String?> testAuth() async {
    if (_tokens[id] == null) return "Missing token";
    return await _mr.users.getAuthorizedUser() != null ? null : "Invalid token";
  }

  @override
  Future<Uri> upload(Project project, UploadRequest request) async {
    ModrinthVersion newVersion;
    try {
      newVersion = await _mr.versions.create(
        CreateVersion(
          request.title,
          request.version,
          request.relations
              .where((e) => e.projectIdByPlatform.containsKey(id))
              .map((e) => CreateDependency(e.projectIdByPlatform[id]!, e.type))
              .toList(),
          request.compatibleGameVersions,
          request.releaseType.toModrinth(),
          project.loaders,
          false,
          project.idByService[id]!,
          request.files.map((e) => basename(e.path)).toList(),
          basename(request.files.first.path),
          changelog: request.changelog,
        ),
        request.files,
      );
    } on ModrinthException catch (e) {
      throw UploadException("Modrinth API returned an error: ${e.error} / ${e.description}");
    }

    return Uri.parse("https://modrinth.com/${project.type.name}/${project.idByService[id]!}/version/${newVersion.id}");
  }
}

extension on ReleaseType {
  ModrinthVersionType toModrinth() => switch (this) {
        ReleaseType.alpha => ModrinthVersionType.alpha,
        ReleaseType.beta => ModrinthVersionType.beta,
        ReleaseType.release => ModrinthVersionType.release
      };
}
