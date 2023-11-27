import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:synk/command/config_command.dart';
import 'package:synk/command/create_command.dart';
import 'package:synk/command/delete_command.dart';
import 'package:synk/command/edit_command.dart';
import 'package:synk/command/index_command.dart';
import 'package:synk/command/pre_flight_command.dart';
import 'package:synk/command/setup_command.dart';
import 'package:synk/command/upload_command.dart';
import 'package:synk/config/config.dart';
import 'package:synk/config/database.dart';
import 'package:synk/config/options.dart';
import 'package:synk/config/tokens.dart';
import 'package:synk/terminal/ansi.dart' as c;
import 'package:synk/terminal/console.dart';
import 'package:synk/upload/curseforge_service.dart';
import 'package:synk/upload/github_service.dart';
import 'package:synk/upload/modrinth_service.dart';
import 'package:synk/upload/upload_service.dart';

const _configDirEnv = "SYNK_CONFIG_DIR";

Future<void> main(List<String> arguments) async {
  final client = Client();

  final configProvider = ConfigProvider(Platform.environment[_configDirEnv] ?? "synk");
  if (Platform.environment.containsKey(_configDirEnv)) {
    print(c.hint("Using custom config directory '${Platform.environment[_configDirEnv]}'"));
  }

  final db = ProjectDatabase(configProvider);
  final tokens = TokenStore(configProvider);
  final config = SynkConfig(configProvider);

  final mr = ModrinthApi.createClient("gliscowo/synk", token: tokens["modrinth"]);
  final uploadServices = UploadServices([
    ModrinthUploadService(mr, tokens),
    CurseForgeUploadService(client, tokens),
    GitHubUploadService(tokens, client),
  ]);

  final configOptions = createConfigOptions(mr);
  final projectOptions = createProjectOptions(uploadServices, mr);

  final runner = CommandRunner<void>("synk", "monochrome to colors")
    ..addCommand(CreateCommand(db, mr, uploadServices, config))
    ..addCommand(DeleteCommand(db))
    ..addCommand(IndexCommand(db))
    ..addCommand(ConfigCommand(config, tokens, uploadServices, configOptions))
    ..addCommand(EditCommand(db, config, configOptions, projectOptions))
    ..addCommand(SetupCommand(tokens, uploadServices, config, configOptions))
    ..addCommand(PreFlightCommand(config, db, uploadServices))
    ..addCommand(UploadCommand(configProvider, config, db, mr, uploadServices));

  if (!config.setupCompleted) {
    arguments = const ["setup"];
  }

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
