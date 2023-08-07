import 'package:synk/config/config.dart';
import 'package:test/test.dart';

void main() {
  group('config', () {
    test('overlay', () {
      final provider = ConfigOnlyConfigProvider();
      // final
    });
  });
}

class ConfigOnlyConfigProvider implements ConfigProvider {
  Map<String, dynamic>? configData;

  @override
  void deleteConfigData(String name, {List<String> path = const []}) => throw UnimplementedError();

  @override
  Iterable<(String, Map<String, dynamic> Function())> listAllIn(List<String> path) => throw UnimplementedError();

  @override
  Map<String, dynamic>? readConfigData(String name, {List<String> path = const []}) =>
      name == "global_config" ? configData : throw ArgumentError("global config accessed incorrect file");

  @override
  void saveConfigData(String name, Map<String, dynamic> content, {List<String> path = const []}) =>
      configData = content;
}
