import 'touch_action.dart';

/// Represents a gesture event with action type and coordinates
class GestureEvent {
  final TouchAction action;
  final double x;
  final double y;
  final DateTime timestamp;

  GestureEvent({
    required this.action,
    required this.x,
    required this.y,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

