abstract class KeyboardCommandExecutor {
  Future<void> keyPress(String key, {bool ctrl = false, bool alt = false, bool shift = false, bool meta = false});
  Future<void> keyRelease(String key, {bool ctrl = false, bool alt = false, bool shift = false, bool meta = false});
  Future<void> modifierPress(String modifier);
  Future<void> modifierRelease(String modifier);
}

