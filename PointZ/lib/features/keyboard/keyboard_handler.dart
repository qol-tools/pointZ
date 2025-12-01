import 'interfaces/keyboard_command_executor.dart';

class KeyboardHandler {
  final KeyboardCommandExecutor _executor;

  KeyboardHandler(this._executor);

  Future<void> handleKeyPress(String key, {bool ctrl = false, bool alt = false, bool shift = false, bool meta = false}) async {
    await _executor.keyPress(key, ctrl: ctrl, alt: alt, shift: shift, meta: meta);
  }

  Future<void> handleKeyRelease(String key, {bool ctrl = false, bool alt = false, bool shift = false, bool meta = false}) async {
    await _executor.keyRelease(key, ctrl: ctrl, alt: alt, shift: shift, meta: meta);
  }

  Future<void> handleModifierPress(String modifier) async {
    await _executor.modifierPress(modifier);
  }

  Future<void> handleModifierRelease(String modifier) async {
    await _executor.modifierRelease(modifier);
  }
}

