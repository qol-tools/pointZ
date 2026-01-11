import '../../../domain/models/touch_action.dart';

class GestureState {
  TouchAction previousTapAction = TouchAction.none;
  TouchAction previousTouchAction = TouchAction.none;
  double previousX = 0;
  double previousY = 0;
  DateTime? lastMoveTime;
  bool moving = false;
  bool scrolling = false;
  bool holdingPrimaryMouseButton = false;
  bool canDoubleClick = false;
  bool waitingForSecondTap = false;
  DateTime? rightClickCooldownUntil;
  bool rightClickJustSent = false;
  DateTime? secondTapHoldStartTime;
  bool inDragMode = false;
  bool movedSinceLastDown = false;
  bool dragModeJustActivated = false;

  void reset() {
    previousTapAction = TouchAction.none;
    previousTouchAction = TouchAction.none;
    previousX = 0;
    previousY = 0;
    lastMoveTime = null;
    moving = false;
    scrolling = false;
    holdingPrimaryMouseButton = false;
    canDoubleClick = false;
    waitingForSecondTap = false;
    rightClickCooldownUntil = null;
    rightClickJustSent = false;
    secondTapHoldStartTime = null;
    inDragMode = false;
    movedSinceLastDown = false;
    dragModeJustActivated = false;
  }

  void cancelSingleClick() {
    waitingForSecondTap = false;
    canDoubleClick = false;
  }

  /// Returns true if we're currently in a right-click cooldown period
  bool isInRightClickCooldown() {
    return rightClickCooldownUntil != null &&
        DateTime.now().isBefore(rightClickCooldownUntil!);
  }

  /// Returns true if we should ignore events due to recent right-click
  bool shouldIgnoreDueToRightClick() {
    return rightClickJustSent || isInRightClickCooldown();
  }
}

