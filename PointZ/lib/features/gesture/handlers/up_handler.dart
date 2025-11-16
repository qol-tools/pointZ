import '../../../domain/models/touch_action.dart';
import '../state/gesture_state.dart';
import '../../../features/mouse_control/interfaces/mouse_command_executor.dart';

class UpHandler {
  final GestureState _state;
  final MouseCommandExecutor _executor;

  UpHandler(this._state, this._executor);

  Future<void> handle() async {
    if (_state.shouldIgnoreDueToRightClick()) {
      _resetState();
      return;
    }

    if (_state.holdingPrimaryMouseButton) {
      await _releaseButton();
      return;
    }

    if (_state.moving) {
      _state.waitingForSecondTap = false;
      _resetState();
      return;
    }

    _resetState();
  }

  Future<void> _releaseButton() async {
    await _executor.mouseUp(1);
    _state.holdingPrimaryMouseButton = false;
  }

  void _resetState() {
    _state.moving = false;
    _state.lastMoveTime = null;
    _state.previousTapAction = TouchAction.none;
  }
}
