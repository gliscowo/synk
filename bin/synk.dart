import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:synk/command/create_command.dart';
import 'package:synk/command/delete_command.dart';
import 'package:synk/command/index_command.dart';
import 'package:synk/command/pre_flight_command.dart';
import 'package:synk/command/setup_command.dart';
import 'package:synk/config/config.dart';
import 'package:synk/config/database.dart';
import 'package:synk/config/tokens.dart';
import 'package:synk/terminal/ansi.dart' as c;
import 'package:synk/terminal/console.dart';
import 'package:synk/upload/curseforge_service.dart';
import 'package:synk/upload/github_service.dart';
import 'package:synk/upload/modrinth_service.dart';
import 'package:synk/upload/upload_service.dart';

void main(List<String> arguments) async {
  final client = Client();

  final configProvider = const ConfigProvider("synk");
  final db = ProjectDatabase(configProvider);
  final tokens = TokenStore(configProvider);
  final config = SynkConfig(configProvider);

  final mr = ModrinthApi.createClient("gliscowo/synk", token: tokens["modrinth"]);
  UploadService.register(ModrinthUploadService(mr, tokens, config));
  UploadService.register(CurseForgeUploadService(client, tokens));
  UploadService.register(GitHubUploadService(tokens, client));

  final runner = CommandRunner<void>("synk", "monochrome to colors")
    ..addCommand(CreateCommand(db, mr, config))
    ..addCommand(DeleteCommand(db))
    ..addCommand(IndexCommand(db))
    ..addCommand(SetupCommand(tokens))
    ..addCommand(PreFlightCommand(config, db));

  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    print(c.red(e.message));
  } on SynkOut catch (synkOut) {
    exitCode = synkOut.code;
  } finally {
    client.close();
    mr.dispose();
  }
}
