import 'dart:async';

import 'package:args/args.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:synk/command/synk_command.dart';
import 'package:synk/config/config.dart';
import 'package:synk/terminal/changelog_reader.dart';
import 'package:synk/terminal/console.dart';

import '../terminal/ansi.dart' as c;
import '../terminal/spinner.dart';

class ConfigCommand extends SynkCommand {
  final SynkConfig _config;
  final ModrinthApi _mr;
  ConfigCommand(this._config, this._mr)
      : super(
          "config",
          "Edit synk's global configuration",
        );

  @override
  FutureOr<void> execute(ArgResults args) async {
    do {
      final option = console.choose(
        _Option.values,
        "Option to edit",
        formatter: (entry) => entry.title,
        ephemeral: true,
      );

      switch (option) {
        case _Option.changelogReader:
          _config.changelogReader = console.choose<ChangelogReader>(
            ChangelogReader.values,
            "New default changelog reader",
            selected: ChangelogReader.values.indexOf(_config.changelogReader),
            formatter: (entry) => entry.name,
          );

        case _Option.defaultVersions:
          final versions = (await Spinner.wait("Fetching versions", _mr.tags.getGameVersions()))
              .where((e) => e.versionType == ModrinthGameVersionType.release)
              .map((e) => e.version)
              .toList();

          final chosenVersions = console.chooseMultiple(
            versions,
            "Default minecraft versions",
            selected: _config.minecraftVersions,
          );

          _config.minecraftVersions = chosenVersions.isNotEmpty ? chosenVersions : null;
      }
    } while (!console.ask("Done", ephemeral: true));

    print(c.success("Changes applied"));
  }
}

enum _Option {
  defaultVersions("Default Minecraft versions"),
  changelogReader("Changelog reader");

  final String title;
  const _Option(this.title);
}
