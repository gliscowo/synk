import 'config.dart';
import 'types.dart';

class ModDatabase {
  final Map<String, Mod> _cache = {};
  final ConfigProvider _provider;

  ModDatabase(this._provider);

  Mod operator [](String id) {
    var cached = _cache[id];
    if (cached != null) return cached;

    var data = _provider.readConfigData(id, path: ["projects"]);
    if (data == null) {
      throw StateError("No mod with id '$id' in database");
    }

    return _cache[id] = Mod.fromJson(data);
  }

  void operator []=(String id, Mod mod) {
    _cache[id] = mod;
    _provider.saveConfigData(id, mod.toJson(), path: ["projects"]);
  }

  /// Provide an index of all mods currently persisted on disk
  Iterable<Mod> get index => _provider.listAllIn(["projects"]).map((e) => _cache[e.$1] ?? Mod.fromJson(e.$2()));
}
