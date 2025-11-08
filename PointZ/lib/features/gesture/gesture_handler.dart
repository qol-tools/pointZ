import '../../domain/models/gesture_event.dart';
import '../../domain/models/touch_action.dart';
import 'state/gesture_state.dart';
import 'config/gesture_config.dart';
import 'handlers/down_handler.dart';
import 'handlers/up_handler.dart';
import 'handlers/move_handler.dart';
import 'handlers/pointer_handler.dart';
import '../mouse_control/interfaces/mouse_command_executor.dart';

/// Orchestrates gesture handling by delegating to specialized handlers
class GestureHandler {
  final GestureState _state;
  final MouseCommandExecutor _executor;
  late final DownHandler _downHandler;
  late final UpHandler _upHandler;
  late final MoveHandler _moveHandler;
  late final PointerHandler _pointerHandler;

  GestureHandler(this._executor) : _state = GestureState() {
    _downHandler = DownHandler(_state, _executor, _startDoubleClickWindow);
    _upHandler = UpHandler(_state, _executor);
    _moveHandler = MoveHandler(_state, _executor);
    _pointerHandler = PointerHandler(_state, _executor);
  }

  /// Processes a gesture event and routes it to the appropriate handler
  Future<void> handleEvent(GestureEvent event) async {
    // Ignore all events during right-click cooldown
    if (_state.isInRightClickCooldown()) {
      // Don't update previousTouchAction during cooldown
      return;
    }

    switch (event.action) {
      case TouchAction.down:
        await _downHandler.handle(event);
        break;
      case TouchAction.pointer2Down:
      case TouchAction.pointer3Down:
        await _pointerHandler.handleDown(event);
        break;
      case TouchAction.move:
        await _moveHandler.handle(event);
        break;
      case TouchAction.up:
        // Only process up if we're not in cooldown and didn't just send right-click
        if (_state.rightClickJustSent) {
          return;
        }
        if (_state.previousTapAction == TouchAction.pointer2Down ||
            _state.previousTapAction == TouchAction.pointer3Down) {
          await _pointerHandler.handleUp();
        } else {
          await _upHandler.handle();
        }
        break;
      case TouchAction.none:
        break;
    }

    // Only update previousTouchAction if we're not in cooldown
    if (!_state.isInRightClickCooldown()) {
      _state.previousTouchAction = event.action;
    }
  }

  void _startDoubleClickWindow() {
    _state.canDoubleClick = true;
    Future.delayed(Duration(milliseconds: GestureConfig.doubleTapDelayMs), () {
      // Block single click if we're in right-click cooldown
      if (_state.isInRightClickCooldown()) {
        _state.waitingForSecondTap = false;
        _state.canDoubleClick = false;
        return;
      }

      if (_state.waitingForSecondTap &&
          !_state.holdingPrimaryMouseButton) {
        if (!_state.moving) {
          _executor.mouseClick(1);
        }
        _state.waitingForSecondTap = false;
      }
      _state.canDoubleClick = false;
    });
  }

  void reset() {
    _state.reset();
  }
}

