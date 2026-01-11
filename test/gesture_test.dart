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
import 'package:pointz/services/settings_service.dart';

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
  group('DownHandler', () {
    test('first tap sets waitingForSecondTap', () {
      // Arrange
      final state = GestureState();
      bool windowStarted = false;
      final handler = DownHandler(
        state,
        () => windowStarted = true,
      );
      final event = GestureEvent(action: TouchAction.down, x: 10, y: 20);

      // Act
      handler.handle(event);

      // Assert
      expect(state.waitingForSecondTap, true);
      expect(windowStarted, true);
    });

    test('second tap records hold start time', () async {
      // Arrange
      final state = GestureState();
      state.canDoubleClick = true;
      final handler = DownHandler(
        state,
        () {},
      );
      final event = GestureEvent(action: TouchAction.down, x: 10, y: 20);

      // Act
      await handler.handle(event);

      // Assert
      expect(state.waitingForSecondTap, false);
      expect(state.secondTapHoldStartTime, isNotNull);
    });
  });

  group('UpHandler', () {
    test('releases held button', () async {
      // Arrange
      final state = GestureState();
      final executor = MockMouseExecutor();
      state.holdingPrimaryMouseButton = true;
      final handler = UpHandler(state, executor);

      // Act
      await handler.handle();

      // Assert
      expect(state.holdingPrimaryMouseButton, false);
      expect(executor.calls, ['mouseUp(1)']);
    });

    test('does nothing if not holding', () async {
      // Arrange
      final state = GestureState();
      final executor = MockMouseExecutor();
      state.moving = true;
      final handler = UpHandler(state, executor);

      // Act
      await handler.handle();

      // Assert
      expect(executor.calls.isEmpty, true);
      expect(state.moving, false);
    });
  });

  group('MoveHandler', () {
    test('ignores small movements within deadzone', () async {
      // Arrange
      final state = GestureState();
      final executor = MockMouseExecutor();
      final settings = AppSettings();
      final config = GestureConfig(settings);
      state.previousX = 0;
      state.previousY = 0;
      state.previousTapAction = TouchAction.down;
      final handler = MoveHandler(state, executor, config);
      final event = GestureEvent(
        action: TouchAction.move,
        x: config.deadZoneInitial - 1,
        y: config.deadZoneInitial - 1,
      );

      // Act
      await handler.handle(event);

      // Assert
      expect(executor.calls.isEmpty, true);
    });

    test('handles mouse movement when holding', () async {
      // Arrange
      final state = GestureState();
      final executor = MockMouseExecutor();
      final settings = AppSettings();
      final config = GestureConfig(settings);
      state.previousX = 0;
      state.previousY = 0;
      state.previousTapAction = TouchAction.down;
      state.previousTouchAction = TouchAction.move;
      state.moving = true;
      final handler = MoveHandler(state, executor, config);
      final event = GestureEvent(
        action: TouchAction.move,
        x: 50,
        y: 50,
      );

      // Act
      await handler.handle(event);

      // Assert
      final expectedX = 50 * config.mouseSensitivity * config.minAcceleration;
      final expectedY = 50 * config.mouseSensitivity * config.minAcceleration;
      expect(executor.calls, ['mouseMove($expectedX, $expectedY)']);
      expect(state.previousX, 50);
      expect(state.previousY, 50);
    });

    test('handles scroll with two fingers', () async {
      // Arrange
      final state = GestureState();
      final executor = MockMouseExecutor();
      final settings = AppSettings();
      final config = GestureConfig(settings);
      state.previousX = 0;
      state.previousY = 0;
      state.previousTapAction = TouchAction.pointer2Down;
      state.previousTouchAction = TouchAction.move;
      final handler = MoveHandler(state, executor, config);
      final event = GestureEvent(
        action: TouchAction.move,
        x: 0,
        y: 100,
      );

      // Act
      await handler.handle(event);

      // Assert
      expect(executor.calls.length, 1);
      expect(executor.calls[0], contains('mouseScroll'));
    });
  });

  group('PointerHandler', () {
    test('handles two finger tap as right click', () async {
      // Arrange
      final state = GestureState();
      final executor = MockMouseExecutor();
      final settings = AppSettings();
      final config = GestureConfig(settings);
      state.previousTapAction = TouchAction.pointer2Down;
      state.moving = false;
      final handler = PointerHandler(state, executor, config);

      // Act
      await handler.handleUp();
      await Future.delayed(
          Duration(milliseconds: config.rightClickButtonHoldMs + 10));

      // Assert
      expect(executor.calls[0], 'mouseDown(2)');
      expect(executor.calls[1], 'mouseUp(2)');
    });

    test('handles three finger tap as middle click', () async {
      // Arrange
      final state = GestureState();
      final executor = MockMouseExecutor();
      final settings = AppSettings();
      final config = GestureConfig(settings);
      state.previousTapAction = TouchAction.pointer3Down;
      state.moving = false;
      final handler = PointerHandler(state, executor, config);

      // Act
      await handler.handleUp();
      await Future.delayed(
          Duration(milliseconds: config.rightClickButtonHoldMs + 10));

      // Assert
      expect(executor.calls[0], 'mouseDown(3)');
      expect(executor.calls[1], 'mouseUp(3)');
    });

    test('does not click if moving', () async {
      // Arrange
      final state = GestureState();
      final executor = MockMouseExecutor();
      final settings = AppSettings();
      final config = GestureConfig(settings);
      state.previousTapAction = TouchAction.pointer2Down;
      state.moving = true;
      final handler = PointerHandler(state, executor, config);

      // Act
      await handler.handleUp();

      // Assert
      expect(executor.calls.isEmpty, true);
    });
  });
}
