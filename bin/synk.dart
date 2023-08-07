import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:synk/command/create_command.dart';
import 'package:synk/command/delete_command.dart';
import 'package:synk/command/index_command.dart';
import 'package:synk/command/overlay_command.dart';
import 'package:synk/command/setup_command.dart';
import 'package:synk/config/config.dart';
import 'package:synk/config/database.dart';
import 'package:synk/config/tokens.dart';
import 'package:synk/terminal/ansi.dart' as c;
import 'package:synk/terminal/console.dart';

void main(List<String> arguments) async {
  final client = Client();
  final mr = ModrinthApi.createClient("gliscowo/synk");

  final configProvider = const ConfigProvider("synk");
  final db = ProjectDatabase(configProvider);
  final tokens = TokenStore(configProvider);
  final config = SynkConfig(configProvider);

  final runner = CommandRunner<void>("synk", "monochrome to colors")
    ..addCommand(CreateCommand(db, mr))
    ..addCommand(DeleteCommand(db))
    ..addCommand(IndexCommand(db))
    ..addCommand(SetupCommand(tokens))
    ..addCommand(OverlayCommand(config, db));

  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    print("${c.red}${e.message}${c.reset}");
    runner.printUsage();
  } on SynkOut catch (synkOut) {
    exitCode = synkOut.code;
  } finally {
    client.close();
    mr.dispose();
  }
}
