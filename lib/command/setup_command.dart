import 'dart:async';

import 'package:args/args.dart';
import 'package:synk/config/tokens.dart';
import 'package:synk/terminal/console.dart';

import 'synk_command.dart';

class SetupCommand extends SynkCommand {
  final TokenStore _tokens;
  SetupCommand(this._tokens)
      : super(
          "setup",
          "Re-run synk's first-time setup process",
        );

  @override
  FutureOr<void> execute(ArgResults args) {
    final platformChoices = ["Modrinth", "GitHub", "CurseForge"];
    do {
      var platform = console.choose(platformChoices, "Select platform");
      platformChoices.remove(platform);

      var token = console.prompt("Token (leave blank to remove)", secret: true);
      _tokens[platform.toLowerCase()] = token.isNotEmpty ? token : null;
    } while (platformChoices.isNotEmpty && console.ask("Add more"));
  }
}
