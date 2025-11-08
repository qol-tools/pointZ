import 'package:flutter_test/flutter_test.dart';
import 'package:pointz/domain/models/touch_action.dart';
import 'package:pointz/domain/models/gesture_event.dart';
import 'package:pointz/features/gesture/gesture_handler.dart';
import 'package:pointz/features/gesture/config/gesture_config.dart';
import 'package:pointz/features/mouse_control/interfaces/mouse_command_executor.dart';
import 'dart:async';

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

    setUp(() {
      executor = MockMouseExecutor();
      handler = GestureHandler(executor);
    });

    test('single tap performs single click after delay', () async {
      final downEvent = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );
      
      await handler.handleEvent(downEvent);
      
      // Wait for double-click window to expire
      await Future.delayed(Duration(milliseconds: GestureConfig.doubleTapDelayMs + 50));
      
      expect(executor.calls, ['mouseClick(1)']);
    });

    test('double tap and hold starts holding', () async {
      // First tap
      final firstDown = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );
      await handler.handleEvent(firstDown);
      
      // Wait a bit but within window
      await Future.delayed(Duration(milliseconds: 50));
      
      // Second tap within window
      final secondDown = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );
      await handler.handleEvent(secondDown);
      
      expect(executor.calls, ['mouseDown(1)']);
    });

    test('double tap and hold then drag moves mouse', () async {
      // First tap
      final firstDown = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );
      await handler.handleEvent(firstDown);
      
      // Second tap within window
      final secondDown = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );
      await handler.handleEvent(secondDown);
      
      // Move while holding
      final moveEvent = GestureEvent(
        action: TouchAction.move,
        x: 60,
        y: 70,
      );
      await handler.handleEvent(moveEvent);
      
      // Release
      final upEvent = GestureEvent(
        action: TouchAction.up,
        x: 0,
        y: 0,
      );
      await handler.handleEvent(upEvent);
      
      expect(executor.calls[0], 'mouseDown(1)');
      expect(executor.calls[1], contains('mouseMove'));
      expect(executor.calls[2], 'mouseUp(1)');
    });

    test('movement cancels double-click window', () async {
      // First tap
      final firstDown = GestureEvent(
        action: TouchAction.down,
        x: 10,
        y: 20,
      );
      await handler.handleEvent(firstDown);
      
      // Move beyond deadzone
      final moveEvent = GestureEvent(
        action: TouchAction.move,
        x: 10 + GestureConfig.deadZoneInitial + 1,
        y: 20 + GestureConfig.deadZoneInitial + 1,
      );
      await handler.handleEvent(moveEvent);
      
      // Wait for double-click window
      await Future.delayed(Duration(milliseconds: GestureConfig.doubleTapDelayMs + 50));
      
      // Should not have clicked because movement cancelled it
      expect(executor.calls.isEmpty, true);
    });

    test('two finger tap performs right click', () async {
      final downEvent = GestureEvent(
        action: TouchAction.pointer2Down,
        x: 10,
        y: 20,
      );
      await handler.handleEvent(downEvent);
      
      final upEvent = GestureEvent(
        action: TouchAction.up,
        x: 0,
        y: 0,
      );
      await handler.handleEvent(upEvent);
      
      expect(executor.calls, ['mouseClick(2)']);
    });

    test('three finger tap performs middle click', () async {
      final downEvent = GestureEvent(
        action: TouchAction.pointer3Down,
        x: 10,
        y: 20,
      );
      await handler.handleEvent(downEvent);
      
      final upEvent = GestureEvent(
        action: TouchAction.up,
        x: 0,
        y: 0,
      );
      await handler.handleEvent(upEvent);
      
      expect(executor.calls, ['mouseClick(3)']);
    });
  });
}

