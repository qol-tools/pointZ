import 'dart:async';
import '../../../domain/models/gesture_event.dart';
import '../../../domain/models/touch_action.dart';
import '../state/gesture_state.dart';
import '../config/gesture_config.dart';
import '../../mouse_control/interfaces/mouse_command_executor.dart';

class PointerHandler {
  final GestureState _state;
  final MouseCommandExecutor _executor;

  PointerHandler(this._state, this._executor);

  Future<void> handleDown(GestureEvent event) async {
    // Cancel any pending single-click timer when two-finger gesture starts
    _state.cancelSingleClick();

    // Ignore if we should block due to recent right-click
    if (_state.shouldIgnoreDueToRightClick()) {
      return;
    }

    _state.scrolling = false;
    _state.moving = false;
    _state.previousX = event.x;
    _state.previousY = event.y;
    _state.previousTapAction = event.action;
  }

  Future<void> handleUp() async {
    // Ignore if we should block due to recent right-click
    if (_state.shouldIgnoreDueToRightClick()) {
      // Don't reset previousTapAction during cooldown - keep it so we know it was a pointer gesture
      return;
    }

    if (!_state.moving && !_state.scrolling) {
      final button = _getMouseButton(_state.previousTapAction);
      
      // Cancel any pending single-click timer
      _state.cancelSingleClick();
      
      // Set cooldown IMMEDIATELY before sending click to block all subsequent events
      _state.rightClickCooldownUntil = DateTime.now().add(
        Duration(milliseconds: GestureConfig.rightClickCooldownMs),
      );
      _state.rightClickJustSent = true;
      
      // Use mouseDown + mouseUp with delay
      await _executor.mouseDown(button);
      await Future.delayed(Duration(milliseconds: GestureConfig.rightClickButtonHoldMs));
      await _executor.mouseUp(button);
      
      // Reset the flag after cooldown
      Future.delayed(Duration(milliseconds: GestureConfig.rightClickCooldownMs), () {
        _state.rightClickJustSent = false;
        // Only reset previousTapAction after cooldown completes
        _state.previousTapAction = TouchAction.none;
      });
    } else {
      _state.scrolling = false;
      _state.moving = false;
      _state.previousTapAction = TouchAction.none;
    }
  }

  /// Maps TouchAction to mouse button number
  int _getMouseButton(TouchAction action) {
    return action == TouchAction.pointer2Down ? 2 : 3;
  }
}

