import 'package:modrinth_api/modrinth_api.dart';
import 'package:synk/config/config.dart';
import 'package:synk/config/database.dart';
import 'package:synk/config/project.dart';
import 'package:test/test.dart';

void main() {
  group('config', () {
    late final ConfigProvider provider;
    late SynkConfig config;
    late ProjectDatabase db;

    setUpAll(() {
      provider = TestConfigProvider();
      config = SynkConfig(provider);
      db = ProjectDatabase(provider);
    });

    test('store and load', () {
      db["affinity"] = Project(ModrinthProjectType.mod, "Affinity", "affinity", ["fabric"], [], {}, null, null, {});
      config.minecraftVersions = ["1.18"];

      config = SynkConfig(provider);
      expect(config.minecraftVersions, ["1.18"]);

      db = ProjectDatabase(provider);
      expect(db["affinity"], isNotNull);
    });

    test('overlay', () {
      config.overlay = ConfigOverlay.ofProject(db, db["affinity"]!);
      config.minecraftVersions = ["1.16"];
      expect(config.minecraftVersions, ["1.16"]);

      config.overlay = null;
      expect(config.minecraftVersions, ["1.18"]);
    });
  });
}

class TestConfigProvider implements ConfigProvider {
  final Map<(String, List<String>), Map<String, dynamic>> _storage = {};

  @override
  void deleteConfigData(String name, {List<String> path = const []}) => _storage.remove((name, path));

  @override
  Iterable<(String, Map<String, dynamic> Function())> listAllIn(List<String> path) =>
      _storage.entries.where((element) => element.key.$2 == path).map((e) => (e.key.$1, () => e.value));

  @override
  Map<String, dynamic>? readConfigData(String name, {List<String> path = const []}) => _storage[(name, path)];

  @override
  void saveConfigData(String name, Map<String, dynamic> content, {List<String> path = const []}) =>
      _storage[(name, path)] = content;
}
