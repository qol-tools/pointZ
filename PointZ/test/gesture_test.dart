import 'package:flutter_test/flutter_test.dart';
import 'package:pointz/domain/models/touch_action.dart';
import 'package:pointz/domain/models/gesture_event.dart';
import 'package:pointz/features/gesture/state/gesture_state.dart';
import 'package:pointz/features/gesture/config/gesture_config.dart';
import 'package:pointz/features/mouse_control/interfaces/mouse_command_executor.dart';
import 'package:pointz/features/gesture/handlers/down_handler.dart';
import 'package:pointz/features/gesture/handlers/up_handler.dart';
import 'package:pointz/features/gesture/handlers/move_handler.dart';
import 'package:pointz/features/gesture/handlers/pointer_handler.dart';

class MockMouseExecutor implements MouseCommandExecutor {
  final List<String> _calls = [];
  
  List<String> get calls => List.unmodifiable(_calls);
  void clear() => _calls.clear();

  @override
  Future<void> mouseMove(double x, double y) async {
    _calls.add('mouseMove($x, $y)');
  }

  @override
  Future<void> mouseClick(int button) async {
    _calls.add('mouseClick($button)');
  }

  @override
  Future<void> mouseDown(int button) async {
    _calls.add('mouseDown($button)');
  }

  @override
  Future<void> mouseUp(int button) async {
    _calls.add('mouseUp($button)');
  }

  @override
  Future<void> mouseScroll(double deltaX, double deltaY) async {
    _calls.add('mouseScroll($deltaX, $deltaY)');
  }
}

void main() {
  group('GestureState', () {
    test('reset clears all state', () {
      final state = GestureState();
      state.previousTapAction = TouchAction.down;
      state.moving = true;
      state.holdingPrimaryMouseButton = true;
      
      state.reset();
      
      expect(state.previousTapAction, TouchAction.none);
      expect(state.moving, false);
      expect(state.holdingPrimaryMouseButton, false);
    });
  });

  group('DownHandler', () {
    test('first tap sets waitingForSecondTap', () {
      final state = GestureState();
      final executor = MockMouseExecutor();
      bool windowStarted = false;
      
      final handler = DownHandler(
        state,
        executor,
        () => windowStarted = true,
      );
      
      final event = GestureEvent(action: TouchAction.down, x: 10, y: 20);
      handler.handle(event);
      
      expect(state.waitingForSecondTap, true);
      expect(windowStarted, true);
      expect(executor.calls.isEmpty, true);
    });

    test('second tap within window starts holding', () async {
      final state = GestureState();
      final executor = MockMouseExecutor();
      state.canDoubleClick = true;
      
      final handler = DownHandler(
        state,
        executor,
        () {},
      );
      
      final event = GestureEvent(action: TouchAction.down, x: 10, y: 20);
      await handler.handle(event);
      
      expect(state.waitingForSecondTap, false);
      expect(state.holdingPrimaryMouseButton, true);
      expect(executor.calls, ['mouseDown(1)']);
    });
  });

  group('UpHandler', () {
    test('releases held button', () async {
      final state = GestureState();
      final executor = MockMouseExecutor();
      state.holdingPrimaryMouseButton = true;
      
      final handler = UpHandler(state, executor);
      await handler.handle();
      
      expect(state.holdingPrimaryMouseButton, false);
      expect(executor.calls, ['mouseUp(1)']);
    });

    test('does nothing if not holding', () async {
      final state = GestureState();
      final executor = MockMouseExecutor();
      state.moving = true;
      
      final handler = UpHandler(state, executor);
      await handler.handle();
      
      expect(executor.calls.isEmpty, true);
      expect(state.moving, false);
    });
  });

  group('MoveHandler', () {
    test('ignores small movements within deadzone', () async {
      final state = GestureState();
      final executor = MockMouseExecutor();
      state.previousX = 0;
      state.previousY = 0;
      state.previousTapAction = TouchAction.down;
      
      final handler = MoveHandler(state, executor);
      final event = GestureEvent(
        action: TouchAction.move,
        x: GestureConfig.deadZoneInitial - 1,
        y: GestureConfig.deadZoneInitial - 1,
      );
      
      await handler.handle(event);
      
      expect(executor.calls.isEmpty, true);
    });

    test('handles mouse movement when holding', () async {
      final state = GestureState();
      final executor = MockMouseExecutor();
      state.previousX = 0;
      state.previousY = 0;
      state.previousTapAction = TouchAction.down;
      state.previousTouchAction = TouchAction.move;
      state.moving = true;
      
      final handler = MoveHandler(state, executor);
      final event = GestureEvent(
        action: TouchAction.move,
        x: 50,
        y: 50,
      );
      
      await handler.handle(event);
      
      expect(executor.calls, ['mouseMove(50.0, 50.0)']);
      expect(state.previousX, 50);
      expect(state.previousY, 50);
    });

    test('handles scroll with two fingers', () async {
      final state = GestureState();
      final executor = MockMouseExecutor();
      state.previousX = 0;
      state.previousY = 0;
      state.previousTapAction = TouchAction.pointer2Down;
      state.previousTouchAction = TouchAction.move;
      
      final handler = MoveHandler(state, executor);
      final event = GestureEvent(
        action: TouchAction.move,
        x: 0,
        y: 100,
      );
      
      await handler.handle(event);
      
      expect(executor.calls.length, 1);
      expect(executor.calls[0], contains('mouseScroll'));
    });
  });

  group('PointerHandler', () {
    test('handles two finger tap as right click', () async {
      final state = GestureState();
      final executor = MockMouseExecutor();
      state.previousTapAction = TouchAction.pointer2Down;
      state.moving = false;
      
      final handler = PointerHandler(state, executor);
      await handler.handleUp();
      
      expect(executor.calls, ['mouseClick(2)']);
    });

    test('handles three finger tap as middle click', () async {
      final state = GestureState();
      final executor = MockMouseExecutor();
      state.previousTapAction = TouchAction.pointer3Down;
      state.moving = false;
      
      final handler = PointerHandler(state, executor);
      await handler.handleUp();
      
      expect(executor.calls, ['mouseClick(3)']);
    });

    test('does not click if moving', () async {
      final state = GestureState();
      final executor = MockMouseExecutor();
      state.previousTapAction = TouchAction.pointer2Down;
      state.moving = true;
      
      final handler = PointerHandler(state, executor);
      await handler.handleUp();
      
      expect(executor.calls.isEmpty, true);
    });
  });
}

