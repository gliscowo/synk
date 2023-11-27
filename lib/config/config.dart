import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_console/dart_console.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart';

import '../terminal/changelog_reader.dart';
import 'database.dart';
import 'project.dart';

part 'config.g.dart';

const _jsonEncoder = JsonEncoder.withIndent("  ");

typedef Json = Map<String, dynamic>;

class ConfigProvider {
  final String _baseDir;
  const ConfigProvider(this._baseDir);

  /// Serialize [content] into `<name>.json`. The file's location
  /// may be further differentiated using [path], which is preprended
  void saveConfigData(String name, Json content, {List<String> path = const []}) {
    var file = _resolve(name, path);
    var parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    file.writeAsStringSync(_jsonEncoder.convert(content));
  }

  /// Deserialize `<name>.json`. The file's location
  /// may be further differentiated using [path], which is preprended
  Json? readConfigData(String name, {List<String> path = const []}) {
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
  Iterable<(String, Json Function())> listAllIn(List<String> path) {
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

  String get _baseDirectory => isAbsolute(_baseDir)
      ? _baseDir
      : Platform.isWindows
          ? join(Platform.environment["APPDATA"]!, _baseDir)
          : join(Platform.environment["HOME"]!, ".config", _baseDir);
}

class SynkConfig {
  static const _filename = "global_config";

  final ConfigProvider _provider;
  ConfigOverlay? _overlay;

  bool _setupCompleted = false;
  List<String>? _defaultMinecraftVersions;
  ChangelogReader? _changelogReader;
  String? _versionNamePattern;

  SynkConfig(this._provider) {
    _load();
  }

  /// Update (or clear) the overlay used by this config
  /// instance and load the then-effective overrides
  set overlay(ConfigOverlay? overlay) {
    _overlay = overlay;
    _load();
  }

  bool get setupCompleted => _setupCompleted;
  set setupCompleted(bool value) {
    _setupCompleted = value;
    _save();
  }

  String get versionNamePattern => _versionNamePattern ?? "[{game_version}] {project_name} - {version}";
  set versionNamePattern(String? value) {
    _versionNamePattern = value;
    _save();
  }

  List<String> get minecraftVersions => UnmodifiableListView(_defaultMinecraftVersions ?? const []);
  set minecraftVersions(List<String>? value) {
    _defaultMinecraftVersions = value;
    _save();
  }

  ChangelogReader get changelogReader => _changelogReader ?? ChangelogReader.prompt;
  set changelogReader(ChangelogReader? value) {
    _changelogReader = value;
    _save();
  }

  void _load() {
    var json = _provider.readConfigData(_filename) ?? ConfigData.defaultValues.toJson();
    if (_overlay != null) {
      json.addAll(_overlay!.overrides);
    }

    var data = ConfigData.fromJson(json);
    _defaultMinecraftVersions = data.defaultMinecraftVersions;
    _changelogReader = data.changelogReader;
    _versionNamePattern = data.versionNamePattern;
    _setupCompleted = data.setupCompleted;
  }

  void _save() {
    var json = _getData().toJson();

    if (_overlay != null) {
      var overlay = _overlay;
      this.overlay = null;

      var jsonWithoutOverlay = _getData().toJson();
      json.removeWhere((key, value) => const DeepCollectionEquality().equals(value, jsonWithoutOverlay[key]));

      this.overlay = overlay;
      _overlay?.overrides = json;
    } else {
      _provider.saveConfigData(_filename, json);
    }
  }

  ConfigData _getData() =>
      ConfigData(_defaultMinecraftVersions, _changelogReader, _versionNamePattern, _setupCompleted);

  String get formatted =>
      (Table()..insertRows(_getData().formattedValues.map((e) => [e.$1, e.$2]).toList().cast())).render();
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ConfigData {
  static const defaultValues = ConfigData(null, null, null, false);

  final List<String>? defaultMinecraftVersions;
  final ChangelogReader? changelogReader;
  final String? versionNamePattern;
  @JsonKey(defaultValue: false)
  final bool setupCompleted;

  const ConfigData(this.defaultMinecraftVersions, this.changelogReader, this.versionNamePattern, this.setupCompleted);

  factory ConfigData.fromJson(Map<String, dynamic> json) => _$ConfigDataFromJson(json);
  Map<String, dynamic> toJson() => _$ConfigDataToJson(this);

  Iterable<(String, String?)> get formattedValues => [
        ("Default Minecraft versions", defaultMinecraftVersions?.join(", ")),
        ("Default changelog mode", changelogReader?.name),
        ("Version name pattern", versionNamePattern)
      ];
}

abstract interface class ConfigOverlay {
  Map<String, dynamic> get overrides;
  set overrides(Map<String, dynamic> value);

  /// Create a config overlay which uses [project.configOverlay]
  /// as the override provider and writes [project] to [database]
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
