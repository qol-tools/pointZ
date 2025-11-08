import '../../../domain/models/gesture_event.dart';
import '../state/gesture_state.dart';
import '../../mouse_control/interfaces/mouse_command_executor.dart';

class DownHandler {
  final GestureState _state;
  final MouseCommandExecutor _executor;
  final void Function() _startDoubleClickWindow;

  DownHandler(
    this._state,
    this._executor,
    this._startDoubleClickWindow,
  );

  Future<void> handle(GestureEvent event) async {
    // Reset move time on new gesture
    _state.lastMoveTime = null;
    
    if (_state.canDoubleClick) {
      await _handleSecondTap(event);
    } else {
      _handleFirstTap();
    }

    _state.previousX = event.x;
    _state.previousY = event.y;
    _state.previousTapAction = event.action;
  }

  Future<void> _handleSecondTap(GestureEvent event) async {
    _state.waitingForSecondTap = false;
    await _executor.mouseDown(1);
    _state.holdingPrimaryMouseButton = true;
  }

  void _handleFirstTap() {
    _state.waitingForSecondTap = true;
    _startDoubleClickWindow();
  }
}

