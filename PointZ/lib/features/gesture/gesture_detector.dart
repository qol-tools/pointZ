import 'package:flutter/material.dart';
import '../../domain/models/touch_action.dart';
import '../../domain/models/gesture_event.dart';

class FlutterGestureConverter {
  GestureEvent? _convertScaleStart(ScaleStartDetails details) {
    final action = details.pointerCount == 1
        ? TouchAction.down
        : details.pointerCount == 2
            ? TouchAction.pointer2Down
            : details.pointerCount == 3
                ? TouchAction.pointer3Down
                : TouchAction.none;

    if (action == TouchAction.none) return null;

    return GestureEvent(
      action: action,
      x: details.focalPoint.dx,
      y: details.focalPoint.dy,
    );
  }

  GestureEvent? _convertScaleUpdate(ScaleUpdateDetails details) {
    return GestureEvent(
      action: TouchAction.move,
      x: details.focalPoint.dx,
      y: details.focalPoint.dy,
    );
  }

  GestureEvent _convertScaleEnd(ScaleEndDetails details) {
    return GestureEvent(
      action: TouchAction.up,
      x: 0,
      y: 0,
    );
  }

  GestureEvent? onScaleStart(ScaleStartDetails details) => _convertScaleStart(details);
  GestureEvent? onScaleUpdate(ScaleUpdateDetails details) => _convertScaleUpdate(details);
  GestureEvent onScaleEnd(ScaleEndDetails details) => _convertScaleEnd(details);
}

