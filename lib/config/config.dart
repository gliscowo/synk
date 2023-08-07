import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:synk/config/database.dart';

import 'types.dart';

const _jsonEncoder = JsonEncoder.withIndent("  ");

class ConfigProvider {
  final String _baseDirName;
  const ConfigProvider(this._baseDirName);

  /// Serialize [content] into `<name>.json`. The file's location
  /// may be further differentiated using [path], which is preprended
  void saveConfigData(String name, Map<String, dynamic> content, {List<String> path = const []}) {
    var file = _resolve(name, path);
    var parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    file.writeAsStringSync(_jsonEncoder.convert(content));
  }

  /// Deserialize `<name>.json`. The file's location
  /// may be further differentiated using [path], which is preprended
  Map<String, dynamic>? readConfigData(String name, {List<String> path = const []}) {
    var file = _resolve(name, path);
    return file.existsSync() ? jsonDecode(file.readAsStringSync()) : null;
  }

  /// Delete `<name>.json`. The file's location
  /// may be further differentiated using [path], which is preprended
  void deleteConfigData(String name, {List<String> path = const []}) => _resolve(name, path).deleteSync();

  /// List all `.json` files which were qualified using [path] during saving.
  ///
  /// The returned pair provides the name of each discovered file and a closure
  /// which, when invoked, loads and deserializes the file
  Iterable<(String, Map<String, dynamic> Function())> listAllIn(List<String> path) {
    var dir = Directory(join(_baseDirectory, joinAll(path)));
    if (!dir.existsSync()) return Iterable.empty();

    return dir
        .listSync()
        .whereType<File>()
        .where((file) => extension(file.path) == ".json")
        .map((file) => (basename(file.path), () => jsonDecode(file.readAsStringSync())));
  }

  File _resolve(String name, List<String> path) =>
      File(setExtension(join(_baseDirectory, joinAll(path), name), ".json"));

  String get _baseDirectory => Platform.isWindows
      ? join(Platform.environment["APPDATA"]!, _baseDirName)
      : join(Platform.environment["HOME"]!, ".config", _baseDirName);
}

class SynkConfig {
  final ConfigProvider _provider;
  ConfigOverlay? _overlay;

  List<String>? _defaultMinecraftVersions;

  SynkConfig(this._provider) {
    _load();
  }

  /// Update (or clear) the overlay used by this config
  /// instance and load the then-effective overrides
  set overlay(ConfigOverlay? overlay) {
    _overlay = overlay;
    _load();
  }

  List<String> get defaultMinecraftVersions => UnmodifiableListView(_defaultMinecraftVersions ?? const []);
  set defaultMinecraftVersions(List<String>? versions) {
    _defaultMinecraftVersions = versions;
    _save();
  }

  void _load() {
    var json = _provider.readConfigData("global_config") ?? ConfigData.defaultValues.toJson();
    if (_overlay != null) {
      json.addAll(_overlay!.overrides);
    }

    var data = ConfigData.fromJson(json);
    _defaultMinecraftVersions = data.defaultMinecraftVersions;
  }

  void _save() {
    var json = ConfigData(_defaultMinecraftVersions).toJson();

    if (_overlay != null) {
      _overlay?.overrides = json;
    } else {
      _provider.saveConfigData("global_config", json);
    }
  }
}

abstract interface class ConfigOverlay {
  Map<String, dynamic> get overrides;
  set overrides(Map<String, dynamic> value);

  /// Create a config overlay which uses [project.configOverlay]
  /// as the override provider and persists [project] to [database]
  /// when the overrides are updated
  factory ConfigOverlay.ofProject(ProjectDatabase database, Project project) => _ProjectOverlay(database, project);
}

class _ProjectOverlay implements ConfigOverlay {
  final ProjectDatabase _db;
  final Project _project;
  _ProjectOverlay(this._db, this._project);

  @override
  Map<String, dynamic> get overrides => _project.configOverlay;

  @override
  set overrides(Map<String, dynamic> value) {
    _project.configOverlay = value;
    _db[_project.projectId] = _project;
  }
}

enum ChangelogMode {
  editor,
  prompt,
  file,
}
