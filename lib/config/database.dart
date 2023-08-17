import 'config.dart';
import 'types.dart';

class ProjectDatabase {
  static const _projectPath = ["projects"];

  final Map<String, Project> _cache = {};
  final ConfigProvider _provider;

  ProjectDatabase(this._provider);

  /// Get the project stored under [id] in this database,
  /// loading from disk if necessary
  ///
  /// If no such project is stored, return `null`
  Project? operator [](String id) {
    var cached = _cache[id];
    if (cached != null) return cached;

    var data = _provider.readConfigData(id, path: _projectPath);
    if (data == null) return null;

    return _cache[id] = Project.fromJson(data);
  }

  /// Update [project] (stored under [id]) in the cache of this
  /// database and persist it to disk
  ///
  /// If [project] is `null`, remove whatever is stored under [id}]
  /// from the database and delete the corresponding data from disk
  void operator []=(String id, Project? project) {
    if (project != null) {
      _cache[id] = project;
      _provider.saveConfigData(id, project.toJson(), path: _projectPath);
    } else {
      if (!contains(id)) return;

      _cache[id] == null;
      _provider.deleteConfigData(id, path: _projectPath);
    }
  }

  /// Test whether a project is stored under [id] in this database
  bool contains(String id) => index.any((element) => element.projectId == id);

  /// Provide an index of all mods currently persisted on disk
  Iterable<Project> get index => _provider.listAllIn(_projectPath).map((e) => _cache[e.$1] ?? Project.fromJson(e.$2()));
}
