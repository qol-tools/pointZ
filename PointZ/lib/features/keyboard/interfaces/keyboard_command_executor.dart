abstract class KeyboardCommandExecutor {
  Future<void> keyPress(String key);
  Future<void> keyRelease(String key);
}

