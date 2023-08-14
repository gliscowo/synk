import 'dart:async';

import 'package:args/args.dart';
import 'package:synk/config/tokens.dart';
import 'package:synk/terminal/console.dart';
import 'package:synk/upload/upload_service.dart';

import 'synk_command.dart';

class SetupCommand extends SynkCommand {
  final TokenStore _tokens;
  SetupCommand(this._tokens)
      : super(
          "setup",
          "Re-run synk's first-time setup process",
        );

  @override
  FutureOr<void> execute(ArgResults args) async {
    final services = [...UploadService.registered];
    do {
      var service = console.choose(services, "Select platform", formatter: (entry) => entry.name);
      services.remove(service);

      var token = console.prompt("Token (leave blank to remove)", secret: true);
      _tokens[service.id] = token.isNotEmpty ? token : null;
    } while (services.isNotEmpty && console.ask("Add more"));
  }
}
