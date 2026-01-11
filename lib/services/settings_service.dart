import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _keyMouseSensitivity = 'mouse_sensitivity';
  static const String _keyMinAcceleration = 'min_acceleration';
  static const String _keyMaxAcceleration = 'max_acceleration';
  static const String _keyAccelerationThreshold = 'acceleration_threshold';
  static const String _keyScrollSpeed = 'scroll_speed';

  // Default values matching GestureConfig
  static const double defaultMouseSensitivity = 2.5;
  static const double defaultMinAcceleration = 1.0;
  static const double defaultMaxAcceleration = 1.8;
  static const double defaultAccelerationThreshold = 25.0;
  static const double defaultScrollSpeed = 0.2;

  double mouseSensitivity = defaultMouseSensitivity;
  double minAcceleration = defaultMinAcceleration;
  double maxAcceleration = defaultMaxAcceleration;
  double accelerationThreshold = defaultAccelerationThreshold;
  double scrollSpeed = defaultScrollSpeed;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mouseSensitivity = prefs.getDouble(_keyMouseSensitivity) ?? defaultMouseSensitivity;
    minAcceleration = prefs.getDouble(_keyMinAcceleration) ?? defaultMinAcceleration;
    maxAcceleration = prefs.getDouble(_keyMaxAcceleration) ?? defaultMaxAcceleration;
    accelerationThreshold = prefs.getDouble(_keyAccelerationThreshold) ?? defaultAccelerationThreshold;
    scrollSpeed = prefs.getDouble(_keyScrollSpeed) ?? defaultScrollSpeed;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMouseSensitivity, mouseSensitivity);
    await prefs.setDouble(_keyMinAcceleration, minAcceleration);
    await prefs.setDouble(_keyMaxAcceleration, maxAcceleration);
    await prefs.setDouble(_keyAccelerationThreshold, accelerationThreshold);
    await prefs.setDouble(_keyScrollSpeed, scrollSpeed);
  }

  Future<void> reset() async {
    mouseSensitivity = defaultMouseSensitivity;
    minAcceleration = defaultMinAcceleration;
    maxAcceleration = defaultMaxAcceleration;
    accelerationThreshold = defaultAccelerationThreshold;
    scrollSpeed = defaultScrollSpeed;
    await save();
  }
}

