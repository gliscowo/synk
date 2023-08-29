import 'dart:async';

import 'package:args/args.dart' show ArgResults;

import '../config/config.dart';
import '../config/options.dart';
import '../terminal/ansi.dart' as c;
import '../terminal/console.dart';
import 'synk_command.dart';

class ConfigCommand extends SynkCommand {
  final SynkConfig _config;
  final List<Option<SynkConfig>> _options;

  ConfigCommand(this._config, this._options)
      : super(
          "config",
          "Edit synk's global configuration",
        );

  @override
  FutureOr<void> execute(ArgResults args) async {
    do {
      final option = console.choose(
        _options,
        "Option to edit",
        formatter: (entry) => entry.name,
        ephemeral: true,
      );

      await option.update(_config);
    } while (!console.ask("Done", ephemeral: true));

    print(c.success("Changes applied"));
  }
}
