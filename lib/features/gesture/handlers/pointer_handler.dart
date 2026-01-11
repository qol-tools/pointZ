import 'dart:async';
import '../../../domain/models/gesture_event.dart';
import '../../../domain/models/touch_action.dart';
import '../state/gesture_state.dart';
import '../config/gesture_config.dart';
import '../../mouse_control/interfaces/mouse_command_executor.dart';

class PointerHandler {
  final GestureState _state;
  final MouseCommandExecutor _executor;
  final GestureConfig _config;

  PointerHandler(this._state, this._executor, this._config);

  Future<void> handleDown(GestureEvent event) async {
    _state.cancelSingleClick();

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
    if (_state.shouldIgnoreDueToRightClick()) {
      return;
    }

    if (_state.moving || _state.scrolling) {
      _state.scrolling = false;
      _state.moving = false;
      _state.previousTapAction = TouchAction.none;
      return;
    }

    await _sendPointerClick();
  }

  Future<void> _sendPointerClick() async {
    _state.cancelSingleClick();

    final button = _getMouseButton(_state.previousTapAction);
    _state.rightClickCooldownUntil = DateTime.now().add(
      Duration(milliseconds: _config.rightClickCooldownMs),
    );
    _state.rightClickJustSent = true;

    await _executor.mouseDown(button);
    await Future.delayed(Duration(milliseconds: _config.rightClickButtonHoldMs));
    await _executor.mouseUp(button);

    Future.delayed(Duration(milliseconds: _config.rightClickCooldownMs), () {
      _state.rightClickJustSent = false;
      _state.previousTapAction = TouchAction.none;
    });
  }

  int _getMouseButton(TouchAction action) {
    return action == TouchAction.pointer2Down ? 2 : 3;
  }
}

