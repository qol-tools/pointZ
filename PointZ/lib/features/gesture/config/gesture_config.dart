/// Centralized configuration constants for gesture handling
class GestureConfig {
  static const int deadZoneInitial = 5;
  static const int deadZoneScroll = 10;
  static const int tapDelayMs = 50;
  static const int doubleTapDelayMs = 200;
  static const double scrollSpeed = 0.2;
  static const double mouseSensitivity = 2.5;
  static const int rightClickCooldownMs = 150;
  static const int rightClickButtonHoldMs = 50;
  
  // Acceleration settings
  static const double minAcceleration = 1.0;
  static const double maxAcceleration = 1.8;
  static const double accelerationThreshold = 25.0; // pixels per ms to reach max acceleration
}

