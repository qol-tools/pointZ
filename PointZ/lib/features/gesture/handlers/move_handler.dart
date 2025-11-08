import 'dart:math';
import '../../../domain/models/touch_action.dart';
import '../../../domain/models/gesture_event.dart';
import '../state/gesture_state.dart';
import '../config/gesture_config.dart';
import '../../mouse_control/interfaces/mouse_command_executor.dart';

class MoveHandler {
  final GestureState _state;
  final MouseCommandExecutor _executor;

  MoveHandler(this._state, this._executor);

  Future<void> handle(GestureEvent event) async {
    // Ignore move events if we're not in an active gesture
    if (_state.previousTapAction == TouchAction.none) {
      return;
    }

    // Ignore if in cooldown period after right-click
    if (_state.isInRightClickCooldown()) {
      return;
    }

    final dx = event.x - _state.previousX;
    final dy = event.y - _state.previousY;

    if (_state.previousTouchAction != TouchAction.move) {
      // For pointer2Down, use scroll deadzone; for single finger, use initial deadzone
      final deadzone = _state.previousTapAction == TouchAction.pointer2Down
          ? GestureConfig.deadZoneScroll
          : GestureConfig.deadZoneInitial;

      if (deadzone > dx.abs() && deadzone > dy.abs()) {
        return;
      }

      // Any movement beyond deadzone means we're moving - cancel any pending clicks
      _state.moving = true;
      if (_state.waitingForSecondTap) {
        _state.waitingForSecondTap = false;
      }

      _state.previousX = event.x;
      _state.previousY = event.y;
      return;
    }

    // If we've moved at all, mark as moving (even if within deadzone for subsequent moves)
    // This ensures dragging over context menu doesn't trigger clicks
    if (dx.abs() > 0 || dy.abs() > 0) {
      _state.moving = true;
    }

    switch (_state.previousTapAction) {
      case TouchAction.pointer2Down:
        await _handleScroll(dx, dy, event);
        break;
      case TouchAction.down:
        await _handleMouseMove(dx, dy, event);
        break;
      default:
        break;
    }
  }

  Future<void> _handleScroll(double dx, double dy, GestureEvent event) async {
    if (GestureConfig.deadZoneScroll > dx.abs() &&
        GestureConfig.deadZoneScroll > dy.abs()) {
      return;
    }

    _state.scrolling = true;
    // Make scroll proportional to finger movement for smoother scrolling
    final scrollAmount = dy * GestureConfig.scrollSpeed;
    await _executor.mouseScroll(0, scrollAmount);
    _state.previousX = event.x;
    _state.previousY = event.y;
  }

  Future<void> _handleMouseMove(double dx, double dy, GestureEvent event) async {
    // Calculate acceleration based on movement speed
    final now = DateTime.now();
    double acceleration = GestureConfig.minAcceleration;
    
    if (_state.lastMoveTime != null) {
      final timeDelta = now.difference(_state.lastMoveTime!).inMilliseconds;
      if (timeDelta > 0 && timeDelta < 100) { // Only calculate if reasonable time delta
        final distance = sqrt(dx * dx + dy * dy);
        if (distance > 0) {
          final velocity = distance / timeDelta; // pixels per millisecond
          
          // Apply acceleration: faster movement = higher multiplier
          // Linear interpolation between min and max acceleration
          final velocityRatio = (velocity / GestureConfig.accelerationThreshold).clamp(0.0, 1.0);
          acceleration = GestureConfig.minAcceleration + 
              (GestureConfig.maxAcceleration - GestureConfig.minAcceleration) * velocityRatio;
        }
      }
    }
    
    _state.lastMoveTime = now;
    
    final moveX = dx * GestureConfig.mouseSensitivity * acceleration;
    final moveY = dy * GestureConfig.mouseSensitivity * acceleration;
    
    await _executor.mouseMove(moveX, moveY);
    _state.previousX = event.x;
    _state.previousY = event.y;
  }
}
