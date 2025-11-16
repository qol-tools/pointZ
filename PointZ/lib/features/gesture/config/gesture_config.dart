import '../../../services/settings_service.dart';

/// Configuration for gesture handling
class GestureConfig {
  final AppSettings settings;

  GestureConfig(this.settings);

  // Constants that don't need to be configurable (exposed as instance getters)
  int get deadZoneInitial => 5;
  int get deadZoneScroll => 10;
  int get tapDelayMs => 50;
  int get doubleTapDelayMs => 200;
  int get holdToDragDelayMs => 250;
  int get rightClickCooldownMs => 150;
  int get rightClickButtonHoldMs => 50;

  // Dynamic values from settings
  double get scrollSpeed => settings.scrollSpeed;
  double get mouseSensitivity => settings.mouseSensitivity;
  double get minAcceleration => settings.minAcceleration;
  double get maxAcceleration => settings.maxAcceleration;
  double get accelerationThreshold => settings.accelerationThreshold;
}

