import 'dart:async';

import 'package:args/args.dart';
import 'package:dart_console/dart_console.dart';
import 'package:synk/command/synk_command.dart';
import 'package:synk/config/config.dart';
import 'package:synk/config/database.dart';

import '../terminal/ansi.dart' as c;
import '../terminal/spinner.dart';
import '../upload/upload_service.dart';

class PreFlightCommand extends SynkCommand {
  final SynkConfig _config;
  final ProjectDatabase _db;
  PreFlightCommand(this._config, this._db)
      : super(
          "pre-flight",
          "Run some checks to make sure you're ready for uploading",
        );

  @override
  Future<FutureOr<void>> execute(ArgResults args) async {
    final tokenTable = Table()..title = "Tokens";

    for (final service in UploadService.registered) {
      final result = await Spinner.wait("Pinging ${service.name}", service.testAuth());
      if (result == null) {
        tokenTable.insertRow([service.name, (c.green("✓"))]);
      } else {
        tokenTable.insertRow([service.name, c.red("⚠  $result")]);
      }
    }

    print(tokenTable.render());

    if (_config.minecraftVersions.isNotEmpty) {
      print("${c.green("✓")} Default Minecraft versions: ${_config.minecraftVersions.join(", ")}");
    } else {
      print("${c.yellow("!")} You do have any default Minecraft versions configured");
    }

    final index = _db.index;
    if (index.isNotEmpty) {
      print("${c.green("✓")} ${index.length} projects in database: ${index.map((e) => e.displayName).join(", ")}");
    } else {
      print("${c.yellow("!")} You don't currently have any projects in the databse. Run 'synk create' to get started");
    }
  }
}
