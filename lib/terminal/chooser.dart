import 'dart:math';

import 'package:dart_console/dart_console.dart';

import 'ansi.dart' as c;
import 'console.dart';

typedef EntryFormatter<T> = String Function(T entry);

abstract class _Chooser<T, R> {
  final List<T> _options;
  final EntryFormatter<T>? _formatter;
  int _baseIndex = 0;
  int _focused;

  _Chooser(this._options, this._focused, {EntryFormatter<T>? formatter}) : _formatter = formatter;

  void _keyCallback(Key input);
  R? get _result;

  R choose() {
    console.hideCursor();
    _drawState();

    while (true) {
      final key = console.readKey();
      if (key.controlChar == ControlCharacter.enter && _result != null) break;

      // graceful exit handling (yummy yummy yummy in my tummy tummy tummy)
      if (key.controlChar == ControlCharacter.ctrlC) {
        console.showCursor();
        throw SynkOut(1);
      }

      _keyCallback(key);

      if (key.controlChar == ControlCharacter.arrowUp) {
        _focused = max(0, min(_focused - 1, _options.length - 1));
      } else if (key.controlChar == ControlCharacter.arrowDown) {
        _focused = max(0, min(_focused + 1, _options.length - 1));
      }

      _baseIndex = max(0, min(_focused - 3, _options.length - 6));
      _erase();
      _drawState();
    }

    _erase();
    console.showCursor();
    return _result!;
  }

  void _drawState() {
    for (var i = 0; i < min(_options.length, 6); i++) {
      if (i == 0 && _baseIndex != 0) {
        console.writeLine("  ...");
        continue;
      }

      final entryIdx = _baseIndex + i;
      if (entryIdx >= _options.length) {
        console.writeLine();
        continue;
      }

      if (i == 5 && entryIdx < _options.length - 1) {
        print("  ...");
        continue;
      }

      var entry = _options[entryIdx];
      var entryFormat = "";
      if (entryIdx == _focused) {
        entryFormat += c.bold.code;
        entryFormat += (entry is Formattable ? entry.color : c.white).code;
      } else {
        entryFormat += c.brightBlack.code;
      }

      print((entryIdx == _focused ? "→ " : "  ") + _format(entry, entryIdx, entryFormat));
      console.resetColorAttributes();
    }
  }

  void _erase() {
    for (var i = 0; i < min(_options.length, 6); i++) {
      console.cursorUp();
      console.eraseLine();
    }
  }

  String _format(T t, int idx, String format) {
    return format + (_formatter ?? (t) => t.toString())(t);
  }
}

class Chooser<T> extends _Chooser<T, T> {
  Chooser(super.options, super.focused, {EntryFormatter<T>? formatter}) : super(formatter: formatter);

  @override
  void _keyCallback(Key input) {}
  @override
  T get _result => _options[_focused];
}

class MultiChooser<T> extends _Chooser<T, List<T>> {
  final List<T> _selected;
  final bool _allowNone;

  MultiChooser(super._options, super._focused, this._allowNone, List<T> selected, {EntryFormatter<T>? formatter})
      : _selected = List.from(selected),
        super(formatter: formatter);

  @override
  void _keyCallback(Key input) {
    if (input.char != ' ') return;

    var focused = _options[_focused];
    if (_selected.contains(focused)) {
      _selected.remove(focused);
    } else {
      _selected.add(focused);
    }
  }

  @override
  List<T>? get _result => _allowNone || _selected.isNotEmpty ? _selected : null;

  @override
  String _format(T t, int idx, String format) =>
      (_selected.contains(_options[idx]) ? "${c.green}✓ " : "${c.red}✗ ") + super._format(t, idx, format);
}
