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
  T choose<T>(List<T> options, String prompt, {int selected = 0, EntryFormatter<T>? formatter}) {
    writeLine("$inputColor$prompt ${c.reset}❯ ");

    var chosen = Chooser(options, selected, formatter: formatter).choose();
    cursorUp();
    writeLine("$inputColor$prompt ${c.reset}❯ ${(formatter ?? (e) => e.toString())(chosen)}");

    return chosen;
  }

  /// Ask the user to select multiple elements from [options]
  ///
  /// Entries are formatted by invoking [formatter]
  /// and [selected] can provide a set of entries to pre-select
  List<T> chooseMultiple<T>(List<T> options, String prompt,
      {List<T> selected = const [], bool allowNone = true, EntryFormatter<T>? formatter}) {
    writeLine("$inputColor$prompt ${c.reset}❯ ");

    var chosen = MultiChooser(options, 0, allowNone, selected).choose();
    cursorUp();
    writeLine("$inputColor$prompt ${c.reset}❯ ${chosen.map(formatter ?? (e) => e.toString()).join(", ")}");

    return chosen;
  }

  /// Ask the user to answer [question] with yes or no
  bool ask(String question) {
    write("$inputColor$question? [y/N] ");
    resetColorAttributes();

    return getLine().toLowerCase() == "y";
  }

  /// Ask the user to provide a value in response to [prompt]. If
  /// [secret] is `true`, input will not be echoed to the terminal
  ///
  /// If a [defaultAnswer] is provided, the user can accept by providing
  /// and empty response
  String prompt(String prompt, {String? defaultAnswer, bool secret = false}) {
    write("$inputColor$prompt${defaultAnswer != null ? " ${c.brightBlack}($defaultAnswer)" : ""} ${c.reset}❯ ");

    if (!secret) {
      final input = getLine();
      final answer = input.trim().isEmpty && defaultAnswer != null ? defaultAnswer : input;

      cursorUp();
      writeLine("$inputColor$prompt ${c.reset}❯ $answer");

      return answer;
    }

    stdin.echoMode = false;
    final input = stdin.readLineSync();
    stdin.lineMode = true;
    stdin.echoMode = true;
    writeLine();

    return input ?? "";
  }

  void moveCursor({int up = 0, int down = 0, int left = 0, int right = 0}) {
    for (int i = 0; i < up; i++) {
      cursorUp();
    }
    for (int i = 0; i < down; i++) {
      cursorDown();
    }
    for (int i = 0; i < left; i++) {
      cursorLeft();
    }
    for (int i = 0; i < right; i++) {
      cursorRight();
    }
  }
}

extension Capitalize on String {
  String get capitalized => this[0].toUpperCase() + substring(1);
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
