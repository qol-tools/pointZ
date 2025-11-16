import '../../domain/models/gesture_event.dart';
import '../../domain/models/touch_action.dart';
import 'state/gesture_state.dart';
import 'config/gesture_config.dart';
import 'handlers/down_handler.dart';
import 'handlers/up_handler.dart';
import 'handlers/move_handler.dart';
import 'handlers/pointer_handler.dart';
import '../mouse_control/interfaces/mouse_command_executor.dart';

class GestureHandler {
  final GestureState _state;
  final MouseCommandExecutor _executor;
  final GestureConfig _config;
  late final DownHandler _downHandler;
  late final UpHandler _upHandler;
  late final MoveHandler _moveHandler;
  late final PointerHandler _pointerHandler;

  GestureHandler(this._executor, this._config) : _state = GestureState() {
    _downHandler = DownHandler(_state, _startDoubleClickWindow);
    _upHandler = UpHandler(_state, _executor);
    _moveHandler = MoveHandler(_state, _executor, _config);
    _pointerHandler = PointerHandler(_state, _executor, _config);
  }

  Future<void> handleEvent(GestureEvent event) async {
    if (_state.isInRightClickCooldown()) return;

    switch (event.action) {
      case TouchAction.down:
        await _handleDown(event);
      case TouchAction.pointer2Down || TouchAction.pointer3Down:
        await _pointerHandler.handleDown(event);
      case TouchAction.move:
        await _moveHandler.handle(event);
      case TouchAction.up:
        await _handleUp(event);
      case TouchAction.none:
        break;
    }

    if (!_state.isInRightClickCooldown()) {
      _state.previousTouchAction = event.action;
    }
  }

  Future<void> _handleDown(GestureEvent event) async {
    if (_state.inDragMode) {
      _state.movedSinceLastDown = false;
      return;
    }

    await _downHandler.handle(event);
    if (_state.secondTapHoldStartTime != null) {
      _startHoldToDragTimer();
    }
  }

  Future<void> _handleUp(GestureEvent event) async {
    if (_state.rightClickJustSent) return;

    if (_state.inDragMode) {
      if (!_state.movedSinceLastDown) {
        await _exitDragMode(event);
      } else {
        _state.movedSinceLastDown = false;
      }
      return;
    }

    if (_isPointerAction()) {
      await _pointerHandler.handleUp();
      return;
    }

    await _upHandler.handle();
    _cancelHoldToDragTimer();
  }

  bool _isPointerAction() =>
      _state.previousTapAction == TouchAction.pointer2Down ||
      _state.previousTapAction == TouchAction.pointer3Down;

  Future<void> _exitDragMode(GestureEvent event) async {
    await _executor.mouseUp(1);
    _state.holdingPrimaryMouseButton = false;
    _state.inDragMode = false;
    _state.secondTapHoldStartTime = null;
    _state.moving = false;
    _state.previousX = event.x;
    _state.previousY = event.y;
  }

  void _startDoubleClickWindow() {
    _state.canDoubleClick = true;
    Future.delayed(Duration(milliseconds: _config.doubleTapDelayMs), () {
      if (_state.isInRightClickCooldown()) {
        _resetDoubleClickState();
        return;
      }

      if (_state.waitingForSecondTap && !_state.inDragMode && !_state.moving) {
        _executor.mouseClick(1);
      }

      _resetDoubleClickState();
    });
  }

  void _resetDoubleClickState() {
    _state.waitingForSecondTap = false;
    _state.canDoubleClick = false;
  }

  void _startHoldToDragTimer() {
    Future.delayed(Duration(milliseconds: _config.holdToDragDelayMs), () async {
      if (_state.secondTapHoldStartTime == null || _state.inDragMode) return;

      _state.inDragMode = true;
      _state.dragModeJustActivated = true;
      await _executor.mouseDown(1);
      _state.holdingPrimaryMouseButton = true;
    });
  }

  void _cancelHoldToDragTimer() {
    if (!_state.inDragMode && _state.secondTapHoldStartTime != null) {
      _executor.mouseClick(1);
      _executor.mouseClick(1);
    }

    _state.secondTapHoldStartTime = null;
  }

  void reset() {
    _state.reset();
  }
}
