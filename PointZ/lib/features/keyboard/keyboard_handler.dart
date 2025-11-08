import 'interfaces/keyboard_command_executor.dart';

class KeyboardHandler {
  final KeyboardCommandExecutor _executor;

  KeyboardHandler(this._executor);

  Future<void> handleKeyPress(String key) async {
    await _executor.keyPress(key);
  }

  Future<void> handleKeyRelease(String key) async {
    await _executor.keyRelease(key);
  }
}

