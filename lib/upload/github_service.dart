import 'package:github/github.dart';
import 'package:http/http.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:path/path.dart';

import '../config/project.dart';
import '../config/tokens.dart';
import '../terminal/console.dart';
import 'upload_request.dart';
import 'upload_service.dart';

class GitHubUploadService implements UploadService {
  @override
  final String id = "github";
  @override
  final String name = "GitHub";

  final GitHub _gh;
  final TokenStore _tokens;

  GitHubUploadService(this._tokens, Client client) : _gh = GitHub(client: client) {
    final token = _tokens[id];
    if (token == null) return;

    _gh.auth = Authentication.withToken(token);
  }

  @override
  Future<bool> isProject(String projectId) async {
    try {
      await _gh.repositories.getRepository(RepositorySlug.full(projectId));
      return true;
    } on RepositoryNotFound catch (_) {
      return false;
    }
  }

  @override
  bool supportsProjectType(ModrinthProjectType type) => true;

  @override
  Future<String?> testAuth() async {
    if (_tokens[id] == null) return "Missing token";

    try {
      await _gh.users.getCurrentUser();
      return null;
    } on AccessForbidden catch (error) {
      return error.message ?? "Invalid token";
    }
  }

  @override
  Future<Uri> upload(Project project, UploadRequest request) async {
    final targetCommitish = console.prompt("GitHub tag target commitish (empty for HEAD on remote main branch)");

    Release release;
    try {
      release = await _gh.repositories.createRelease(
        RepositorySlug.full(project.idByService[id]!),
        CreateRelease.from(
          // TODO gh-specific titles
          tagName: request.version,
          name: request.title,
          targetCommitish: targetCommitish,
          isDraft: false,
          isPrerelease: request.releaseType != ReleaseType.release,
        ),
      );
    } on Exception catch (e) {
      throw UploadException(e.toString());
    }

    final assets = (await Future.wait(request.files.map((e) => e.readAsBytes()))).indexed.map((e) {
      final filePath = request.files[e.$1].path;
      return CreateReleaseAsset(
        name: basename(filePath),
        contentType: switch (extension(filePath)) {
          ".zip" || ".litemod" || ".mrpack" => "application/zip",
          ".jar" => "application/java-archive",
          _ => throw ArgumentError("Unsupported file type '${extension(filePath)}'")
        },
        assetData: e.$2,
      );
    });

    await _gh.repositories.uploadReleaseAssets(release, assets);
    return Uri.parse(release.htmlUrl!);
  }
}
