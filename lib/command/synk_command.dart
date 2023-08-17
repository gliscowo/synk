import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../terminal/ansi.dart' as c;

abstract class SynkCommand extends Command<void> {
  @override
  final String name;
  @override
  final String description;

  final List<String> _arguments;

  SynkCommand(this.name, this.description, {List<String> arguments = const []}) : _arguments = arguments;

  @override
  FutureOr<void> run() {
    if (argResults!.rest.length < _arguments.length) {
      final missing = _arguments.sublist(argResults!.rest.length).map((e) => "<$e>");
      print(c.error("Missing ${missing.length == 1 ? "argument" : "arguments"}: ${missing.join(" ")}"));

      printUsage();
      return null;
    }

    return execute(argResults!);
  }

  FutureOr<void> execute(ArgResults args);

  @override
  String get invocation => "${super.invocation} ${_arguments.map((e) => "<$e>").join(" ")}";
}
