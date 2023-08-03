import 'package:dart_console/dart_console.dart';
import 'package:json_annotation/json_annotation.dart';

part 'types.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Mod {
  String displayName;
  String modId;
  List<String> minecraftVersions;
  List<String> loaders;

  Mod(this.displayName, this.modId, this.minecraftVersions, this.loaders);

  String get formatted => (Table()
        ..insertRows([
          ["Display Name", displayName],
          ["Mod ID", modId],
          [],
          ["Minecraft Versions", minecraftVersions.join(", ")],
          ["Loaders", loaders.join(", ")]
        ]))
      .render();

  factory Mod.fromJson(Map<String, dynamic> json) => _$ModFromJson(json);
  Map<String, dynamic> toJson() => _$ModToJson(this);
}
