abstract class MouseCommandExecutor {
  Future<void> mouseMove(double x, double y);
  Future<void> mouseClick(int button);
  Future<void> mouseDown(int button);
  Future<void> mouseUp(int button);
  Future<void> mouseScroll(double deltaX, double deltaY);
}

