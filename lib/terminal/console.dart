import 'dart:io';

import 'package:dart_console/dart_console.dart';

import 'ansi.dart' as c;
import 'chooser.dart';

final console = Console.scrolling();

extension SynkConsole on Console {
  /// Get a full line of input from the user, and throw
  /// a [SynkOut] error if the break character is received
  String getLine() {
    final input = readLine(cancelOnBreak: true);
    if (input == null) throw SynkOut(1);

    return input;
  }

  /// Ask the user to select a single element from [options]
  ///
  /// Entries are formatted by invoking [formatter]
  /// and [selected] can override which entry the picker starts on
  T choose<T>(List<T> options, String prompt,
      {int selected = 0, bool ephemeral = false, EntryFormatter<T>? formatter}) {
    writeLine("$inputColor$prompt ${c.reset}❯ ");

    var chosen = Chooser(options, selected, formatter: formatter).choose();
    cursorUp();
    writeLine("$inputColor$prompt ${c.reset}❯ ${(formatter ?? (e) => e.toString())(chosen)}");

    if (ephemeral) undoLine();
    return chosen;
  }

  /// Ask the user to select multiple elements from [options]
  ///
  /// Entries are formatted by invoking [formatter]
  /// and [selected] can provide a set of entries to pre-select
  List<T> chooseMultiple<T>(List<T> options, String prompt,
      {List<T> selected = const [], bool allowNone = true, bool ephemeral = false, EntryFormatter<T>? formatter}) {
    writeLine("$inputColor$prompt ${c.reset}❯ ");

    var chosen = MultiChooser(options, 0, allowNone, selected, formatter: formatter).choose();
    cursorUp();
    writeLine("$inputColor$prompt ${c.reset}❯ ${chosen.map(formatter ?? (e) => e.toString()).join(", ")}");

    if (ephemeral) undoLine();
    return chosen;
  }

  /// Ask the user to answer [question] with yes or no
  bool ask(String question, {bool ephemeral = false}) {
    write("$inputColor$question? [y/N] ");
    resetColorAttributes();

    final result = getLine().toLowerCase() == "y";
    undoLine();
    return result;
  }

  /// Ask the user to provide a value in response to [prompt]. If
  /// [secret] is `true`, input will not be echoed to the terminal
  ///
  /// If a [defaultAnswer] is provided, the user can accept by providing
  /// and empty response
  String prompt(
    String prompt, {
    String? defaultAnswer,
    bool secret = false,
    bool ephemeral = false,
  }) {
    write("$inputColor$prompt${defaultAnswer != null ? " ${c.brightBlack}($defaultAnswer)" : ""} ${c.reset}❯ ");

    if (!secret) {
      final input = getLine();
      final answer = input.trim().isEmpty && defaultAnswer != null ? defaultAnswer : input;

      cursorUp();
      writeLine("$inputColor$prompt ${c.reset}❯ $answer");

      if (ephemeral) undoLine();
      return answer;
    }

    stdin.echoMode = false;
    final input = stdin.readLineSync();
    stdin.lineMode = true;
    stdin.echoMode = true;
    writeLine();

    if (ephemeral) undoLine();
    return input ?? "";
  }

  /// Wrapper for [SynkConsole.prompt] which allows verifying
  /// the input provided by the user.
  ///
  /// If the input is accepted, [validator] must return `null`,
  /// otherwise it must return a user-friendly string describing the error
  String promptValidated(
    String prompt,
    String? Function(String input) validator, {
    String? defaultAnswer,
    bool secret = false,
    bool ephemeral = false,
    bool allowOverride = false,
  }) {
    String doPrompt(String prompt, String? defaultAnswer) =>
        this.prompt(prompt, defaultAnswer: defaultAnswer, secret: secret);

    var input = doPrompt(prompt, defaultAnswer);

    String? validatorResult;
    while ((validatorResult = validator(input)) != null) {
      print(c.warning("$validatorResult${allowOverride ? ". Press enter again to use it anyways" : ""}"));
      moveCursor(up: 2);

      if (allowOverride) {
        final newInput = doPrompt(prompt, input);
        if (input == newInput) break;

        input = newInput;
      } else {
        eraseLine();
        input = doPrompt(prompt, defaultAnswer);
      }
    }

    eraseLine();
    if (ephemeral) undoLine();

    return input;
  }

  /// Wrapper for [SynkConsole.prompt] which allows verifying
  /// the input provided by the user.
  ///
  /// If the input is accepted, [validator] must return `null`,
  /// otherwise it must return a user-friendly string describing the error
  Future<String> promptValidatedAsync(
    String prompt,
    Future<String?> Function(String input) validator, {
    String? defaultAnswer,
    bool secret = false,
    bool ephemeral = false,
    bool allowOverride = false,
  }) async {
    String doPrompt(String prompt, String? defaultAnswer) =>
        this.prompt(prompt, defaultAnswer: defaultAnswer, secret: secret);

    var input = doPrompt(prompt, defaultAnswer);

    String? validatorResult;
    while ((validatorResult = await validator(input)) != null) {
      print(c.warning("$validatorResult${allowOverride ? ". Press enter again to use it anyways" : ""}"));
      moveCursor(up: 2);

      if (allowOverride) {
        final newInput = doPrompt(prompt, input);
        if (input == newInput) break;

        input = newInput;
      } else {
        eraseLine();
        input = doPrompt(prompt, defaultAnswer);
      }
    }

    eraseLine();
    if (ephemeral) undoLine();

    return input;
  }

  void undoLine() {
    if (cursorPosition?.col == 0) cursorUp();
    eraseLine();
  }

  void moveCursor({int up = 0, int down = 0, int left = 0, int right = 0}) {
    for (int i = 0; i < up; i++) cursorUp(); // ignore: curly_braces_in_flow_control_structures
    for (int i = 0; i < down; i++) cursorDown(); // ignore: curly_braces_in_flow_control_structures
    for (int i = 0; i < left; i++) cursorLeft(); // ignore: curly_braces_in_flow_control_structures
    for (int i = 0; i < right; i++) cursorRight(); // ignore: curly_braces_in_flow_control_structures
  }
}

extension Capitalize on String {
  String get capitalized => this[0].toUpperCase() + substring(1);
}

extension Trunacte on String {
  String truncate(int length) {
    if (this.length <= length) return this;
    return "${substring(0, length)}...${c.reset}";
  }
}

final String inputColor = rgbColor(0x0AA1DD);
final String keyColor = rgbColor(0xFCA17D);
const String valueColor = "${c.ansiEscape}0m";

String rgbColor(int rgb) => "${c.ansiEscape}38;2;${rgb >> 16};${(rgb >> 8) & 0xFF};${rgb & 0xFF}m";

abstract class Formattable {
  c.AnsiControlSequence get color;
}

class SynkOut implements Exception {
  final int code;
  SynkOut(this.code);
}
