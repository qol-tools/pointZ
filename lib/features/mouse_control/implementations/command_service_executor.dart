import '../interfaces/mouse_command_executor.dart';
import '../../../services/command_service.dart';

class CommandServiceExecutor implements MouseCommandExecutor {
  final CommandService _commandService;

  CommandServiceExecutor(this._commandService);

  @override
  Future<void> mouseMove(double x, double y) => _commandService.mouseMove(x, y);

  @override
  Future<void> mouseClick(int button) => _commandService.mouseClick(button);

  @override
  Future<void> mouseDown(int button) => _commandService.mouseDown(button);

  @override
  Future<void> mouseUp(int button) => _commandService.mouseUp(button);

  @override
  Future<void> mouseScroll(double deltaX, double deltaY) =>
      _commandService.mouseScroll(deltaX, deltaY);
}

