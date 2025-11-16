import '../../../domain/models/touch_action.dart';
import '../state/gesture_state.dart';
import '../../../features/mouse_control/interfaces/mouse_command_executor.dart';

class UpHandler {
  final GestureState _state;
  final MouseCommandExecutor _executor;

  UpHandler(this._state, this._executor);

  Future<void> handle() async {
    if (_state.shouldIgnoreDueToRightClick()) {
      _state.moving = false;
      _state.lastMoveTime = null;
      _state.previousTapAction = TouchAction.none;
      return;
    }

    if (_state.holdingPrimaryMouseButton) {
      await _releaseButton();
    } else if (_state.moving) {
      _state.waitingForSecondTap = false;
      _state.moving = false;
      _state.lastMoveTime = null;
      _state.previousTapAction = TouchAction.none;
      return;
    }

    _state.moving = false;
    _state.lastMoveTime = null;
  }

  Future<void> _releaseButton() async {
    await _executor.mouseUp(1);
    _state.holdingPrimaryMouseButton = false;
  }
}
