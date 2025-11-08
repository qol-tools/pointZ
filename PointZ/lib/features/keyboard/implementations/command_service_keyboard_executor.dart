import '../interfaces/keyboard_command_executor.dart';
import '../../../services/command_service.dart';

class CommandServiceKeyboardExecutor implements KeyboardCommandExecutor {
  final CommandService _commandService;

  CommandServiceKeyboardExecutor(this._commandService);

  @override
  Future<void> keyPress(String key) => _commandService.keyPress(key);

  @override
  Future<void> keyRelease(String key) => _commandService.keyRelease(key);
}

