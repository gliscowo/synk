import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

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
