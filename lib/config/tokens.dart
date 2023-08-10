import 'config.dart';

class TokenStore {
  static const _filename = "tokens";

  final ConfigProvider _provider;
  late Map<String, String> _tokens;

  TokenStore(this._provider) {
    _tokens = _provider.readConfigData(_filename)?.cast<String, String>() ?? {};
  }

  /// Get the token stored under the given identifier,
  /// or [null] if no such token is stored
  String? operator [](String identifier) => _tokens[identifier];

  /// Store [token] under [identifier] and persist
  /// that data to disk
  ///
  /// If [token] is [null], remove the token previously
  /// stored under [identifier]
  void operator []=(String identifier, String? token) {
    if (_tokens[identifier] == token) return;

    if (token != null) {
      _tokens[identifier] = token;
    } else {
      _tokens.remove(identifier);
    }

    _provider.saveConfigData(_filename, _tokens);
  }
}
