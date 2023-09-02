import 'dart:async';

import 'package:args/args.dart' show ArgResults;
import 'package:synk/config/tokens.dart';
import 'package:synk/upload/upload_service.dart';

import '../config/config.dart';
import '../config/options.dart';
import '../terminal/ansi.dart' as c;
import '../terminal/console.dart';
import 'synk_command.dart';

final _tokensSentinel = Option<SynkConfig>("Add/change tokens", (_) {});

class ConfigCommand extends SynkCommand {
  final SynkConfig _config;
  final TokenStore _tokens;
  final UploadServices _uploadServices;
  final List<Option<SynkConfig>> _options;

  ConfigCommand(this._config, this._tokens, this._uploadServices, this._options)
      : super(
          "config",
          "Edit synk's global configuration",
        );

  @override
  FutureOr<void> execute(ArgResults args) async {
    do {
      final option = console.choose(
        [..._options, _tokensSentinel],
        "Option to edit",
        formatter: (entry) => entry.name,
        ephemeral: true,
      );

      if (option == _tokensSentinel) {
        var service = console.choose(
          _uploadServices.all,
          "Select platform",
          formatter: (entry) => entry.name,
        );

        var token = console.prompt("Token (leave blank to remove)", secret: true);
        _tokens[service.id] = token.isNotEmpty ? token : null;
      } else {
        await option.update(_config);
      }
    } while (!console.ask("Done", ephemeral: true));

    print(c.success("Changes applied"));
  }
}
