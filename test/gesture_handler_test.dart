import 'package:flutter_test/flutter_test.dart';
import 'package:pointz/domain/models/touch_action.dart';
import 'package:pointz/domain/models/gesture_event.dart';
import 'package:pointz/features/gesture/gesture_handler.dart';
import 'package:pointz/features/gesture/config/gesture_config.dart';
import 'package:pointz/features/mouse_control/interfaces/mouse_command_executor.dart';
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
  group('GestureHandler Integration Tests', () {
    late MockMouseExecutor executor;
    late GestureHandler handler;
    late GestureConfig config;

    setUp(() {
      executor = MockMouseExecutor();
      final settings = AppSettings();
      config = GestureConfig(settings);
      handler = GestureHandler(executor, config);
    });

    test('single tap performs single click after delay', () async {
      // Arrange
      final downEvent = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );

      // Act
      await handler.handleEvent(downEvent);
      await Future.delayed(
          Duration(milliseconds: config.doubleTapDelayMs + 50));

      // Assert
      expect(executor.calls, ['mouseClick(1)']);
    });

    test('double tap and hold starts holding', () async {
      // Arrange
      final firstDown = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );
      final secondDown = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );

      // Act
      await handler.handleEvent(firstDown);
      await Future.delayed(const Duration(milliseconds: 50));
      await handler.handleEvent(secondDown);
      await Future.delayed(
          Duration(milliseconds: config.holdToDragDelayMs + 50));

      // Assert
      expect(executor.calls, ['mouseDown(1)']);
    });

    test('double tap and hold then drag moves mouse', () async {
      // Arrange
      final firstDown = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );
      final secondDown = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );
      final firstMove = GestureEvent(
        action: TouchAction.move,
        x: 15,
        y: 25,
      );
      final secondMove = GestureEvent(
        action: TouchAction.move,
        x: 60,
        y: 70,
      );
      final thirdDown = GestureEvent(
        action: TouchAction.down,
        x: 60,
        y: 70,
      );
      final upEvent = GestureEvent(
        action: TouchAction.up,
        x: 60,
        y: 70,
      );

      // Act
      await handler.handleEvent(firstDown);
      await handler.handleEvent(secondDown);
      await Future.delayed(
          Duration(milliseconds: config.holdToDragDelayMs + 50));
      await handler.handleEvent(firstMove);
      await handler.handleEvent(secondMove);
      await handler.handleEvent(thirdDown);
      await handler.handleEvent(upEvent);

      // Assert
      expect(executor.calls[0], 'mouseDown(1)');
      expect(executor.calls.where((call) => call.contains('mouseMove')).isNotEmpty, true);
      expect(executor.calls.last, 'mouseUp(1)');
    });

    test('movement cancels double-click window', () async {
      // Arrange
      final firstDown = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );
      final moveEvent = GestureEvent(
        action: TouchAction.move,
        x: 10 + config.deadZoneInitial + 1,
        y: 20 + config.deadZoneInitial + 1,
      );

      // Act
      await handler.handleEvent(firstDown);
      await handler.handleEvent(moveEvent);
      await Future.delayed(
          Duration(milliseconds: config.doubleTapDelayMs + 50));

      // Assert
      expect(executor.calls.isEmpty, true);
    });

    test('two finger tap performs right click', () async {
      // Arrange
      final downEvent = GestureEvent(
        action: TouchAction.pointer2Down,
        x: 10,
        y: 20,
      );
      final upEvent = GestureEvent(
        action: TouchAction.up,
        x: 0,
        y: 0,
      );

      // Act
      await handler.handleEvent(downEvent);
      await handler.handleEvent(upEvent);
      await Future.delayed(
          Duration(milliseconds: config.rightClickButtonHoldMs + 10));

      // Assert
      expect(executor.calls[0], 'mouseDown(2)');
      expect(executor.calls[1], 'mouseUp(2)');
    });

    test('three finger tap performs middle click', () async {
      // Arrange
      final downEvent = GestureEvent(
        action: TouchAction.pointer3Down,
        x: 10,
        y: 20,
      );
      final upEvent = GestureEvent(
        action: TouchAction.up,
        x: 0,
        y: 0,
      );

      // Act
      await handler.handleEvent(downEvent);
      await handler.handleEvent(upEvent);
      await Future.delayed(
          Duration(milliseconds: config.rightClickButtonHoldMs + 10));

      // Assert
      expect(executor.calls[0], 'mouseDown(3)');
      expect(executor.calls[1], 'mouseUp(3)');
    });
  });
}
