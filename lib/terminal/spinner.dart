import 'ansi.dart' as c;
import 'console.dart';

const _spinnerIcons = ["⣷", "⣯", "⣟", "⡿", "⢿", "⣻", "⣽", "⣾"];

class Spinner {
  final String Function() _messageSupplier;

  bool _running = false;
  int _iconIndex = 0;

  Spinner.live(this._messageSupplier);
  Spinner.static(String message) : _messageSupplier = (() => message);

  static Future<T> wait<T>(String message, Future<T> value) async {
    final spinner = Spinner.static(message)..start(showElapsedTime: true);

    final result = await value;
    spinner.stop();

    return result;
  }

  void start({bool showElapsedTime = false}) async {
    _running = true;

    final startTime = DateTime.now();
    while (_running) {
      console.eraseLine();
      console.write("\r");

      console.write("${_spinnerIcons[_iconIndex]} ${_messageSupplier()}");

      final elapsed = (DateTime.now().difference(startTime).inMilliseconds / 1000);
      if (showElapsedTime && elapsed >= 1.5) {
        console.write(" ${c.brightBlack}(${elapsed.toStringAsPrecision(2)}s) ${c.reset}");
      }

      _iconIndex = (_iconIndex + 1) % _spinnerIcons.length;
      await Future.delayed(Duration(milliseconds: 75));
    }
  }

  void stop() {
    _running = false;
    console.eraseLine();
    console.write("\r");
  }
}
