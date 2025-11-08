import '../interfaces/keyboard_command_executor.dart';
import '../../../services/command_service.dart';

class CommandServiceKeyboardExecutor implements KeyboardCommandExecutor {
  final CommandService _commandService;

  CommandServiceKeyboardExecutor(this._commandService);

  @override
  Future<void> keyPress(String key, {bool ctrl = false, bool alt = false, bool shift = false, bool meta = false}) =>
      _commandService.keyPress(key, ctrl: ctrl, alt: alt, shift: shift, meta: meta);

  @override
  Future<void> keyRelease(String key, {bool ctrl = false, bool alt = false, bool shift = false, bool meta = false}) =>
      _commandService.keyRelease(key, ctrl: ctrl, alt: alt, shift: shift, meta: meta);

  @override
  Future<void> modifierPress(String modifier) => _commandService.modifierPress(modifier);

  @override
  Future<void> modifierRelease(String modifier) => _commandService.modifierRelease(modifier);
}

