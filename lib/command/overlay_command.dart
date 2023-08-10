import 'dart:async';

import 'package:args/args.dart';
import 'package:synk/terminal/console.dart';

import '../config/config.dart';
import '../config/database.dart';
import 'synk_command.dart';

class OverlayCommand extends SynkCommand {
  final SynkConfig _config;
  final ProjectDatabase _db;
  OverlayCommand(this._config, this._db)
      : super(
          "overlay",
          "Test the config overlay system",
        );

  @override
  FutureOr<void> execute(ArgResults args) {
    if (args.rest case [var overlayProject, ...]) {
      _config.overlay = ConfigOverlay.ofProject(_db, _db[overlayProject]!);
    }

    print("Current values: ${_config.minecraftVersions}");

    var newValue = console.chooseMultiple(
      List.generate(16, (idx) => (idx + 1).toString()),
      "New values",
      selected: _config.minecraftVersions,
    );
    _config.minecraftVersions = newValue.isNotEmpty ? newValue : null;

    _config.overlay = null;
    print("Values without overlay: ${_config.minecraftVersions}");
  }
}
