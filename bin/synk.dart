import 'package:http/http.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:synk/config/config.dart';
import 'package:synk/config/database.dart';
import 'package:synk/config/types.dart';
import 'package:synk/terminal/console.dart';
import 'package:synk/terminal/spinner.dart';

void main(List<String> arguments) async {
  final client = Client();
  final mr = ModrinthApi.createClient("gliscowo/synk");

  final configProvider = const ConfigProvider("synk");
  final db = ModDatabase(configProvider);

  // final runner = CommandRunner<void>("synk", "");

  print("Index:");
  print(db.index.map((e) => e.formatted).join("\n"));

  final versions = (await Spinner.wait("Fetching versions", mr.tags.getGameVersions()))
      .where((e) => e.versionType == ModrinthGameVersionType.release)
      .map((e) => e.version)
      .toList();

  final displayName = console.prompt("Display Name");
  final modId = console.prompt(
    "Mod ID",
    defaultAnswer: displayName
        .toLowerCase()
        .runes
        .where((codeUnit) => codeUnit < 256)
        .map(String.fromCharCode)
        .join()
        .replaceAll(" ", "-"),
  );

  final gameVersions = console.chooseMultiple(versions, "Minecraft Versions", allowNone: false);
  final loaders = console.chooseMultiple(["Fabric", "Forge", "Quilt"], "Modloader(s)", allowNone: false);

  var mod = db[modId] = Mod(displayName, modId, gameVersions, loaders);
  print(mod.formatted);

  try {} finally {
    client.close();
    mr.dispose();
  }
}
