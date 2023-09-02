import 'dart:async';

import 'package:args/args.dart' show ArgResults;

import '../config/config.dart';
import '../config/options.dart';
import '../config/tokens.dart';
import '../terminal/ansi.dart' as c;
import '../terminal/console.dart';
import '../upload/upload_service.dart';
import 'synk_command.dart';

class SetupCommand extends SynkCommand {
  final TokenStore _tokens;
  final UploadServices _uploadServices;

  final SynkConfig _config;
  final List<Option<SynkConfig>> _options;

  SetupCommand(this._tokens, this._uploadServices, this._config, this._options)
      : super(
          "setup",
          "Re-run synk's first-time setup process",
        );

  @override
  FutureOr<void> execute(ArgResults args) async {
    print("${c.brightBlack(">")} Welcome to synk! Before you can start uploading, we need to get some things set up");
    print("${c.brightBlack(">")} First off, let's configure the tokens and platforms to use for uploading:");

    final services = [..._uploadServices.all];
    do {
      var service = console.choose(services, "Select platform", formatter: (entry) => entry.name);
      services.remove(service);

      var token = console.prompt("Token", secret: true);
      _tokens[service.id] = token.isNotEmpty ? token : null;
    } while (services.isNotEmpty && console.ask("Add more"));

    print("${c.brightBlack(">")} Great! Now, let's set up some defaults for synk's global configuration");

    for (final option in _options) {
      await option.update(_config);
    }

    _config.setupCompleted = true;
    print(c.hint("You can always change these selections later by running 'synk config'"));
    print(c.hint(
      "You most likely want to run 'synk create' next and then check you're good to go using 'synk pre-flight'",
    ));
  }
}
