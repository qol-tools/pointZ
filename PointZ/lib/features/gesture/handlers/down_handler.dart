import '../../../domain/models/gesture_event.dart';
import '../state/gesture_state.dart';

class DownHandler {
  final GestureState _state;
  final void Function() _startDoubleClickWindow;

  DownHandler(
    this._state,
    this._startDoubleClickWindow,
  );

  Future<void> handle(GestureEvent event) async {
    _state.lastMoveTime = null;

    if (_state.canDoubleClick) {
      _state.waitingForSecondTap = false;
      _state.secondTapHoldStartTime = DateTime.now();
    } else {
      _state.waitingForSecondTap = true;
      _startDoubleClickWindow();
    }

    _state.previousX = event.x;
    _state.previousY = event.y;
    _state.previousTapAction = event.action;
  }
}

