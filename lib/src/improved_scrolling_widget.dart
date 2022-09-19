import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_improved_scrolling/src/throttler.dart';
import 'config.dart';
import 'custom_scroll_cursor.dart';

/// Current cursor scroll activity
enum MMBScrollCursorActivity {
  /// Middle button pressed, but the cursor is not moving
  idle,

  /// Middle button pressed and the cursor is moving up
  scrollingUp,

  /// Middle button pressed and the cursor is moving down
  scrollingDown,

  /// Middle button pressed and the cursor is moving left
  scrollingLeft,

  /// Middle button pressed and the cursor is moving right
  scrollingRight,
}

/// Improved scrolling for Flutter Web and Desktop
///
/// Must wrap scrollables such as [SingleChildScrollView] or [ListView]
/// in order to provide scrolling features that a normal user
/// would expect from a website or a desktop app
class ImprovedScrolling extends StatefulWidget {
  /// Constructor
  const ImprovedScrolling({
    Key? key,
    required this.scrollController,
    this.enableMMBScrolling = false,
    this.enableKeyboardScrolling = false,
    this.enableCustomMouseWheelScrolling = false,
    this.mmbScrollConfig = const MMBScrollConfig(),
    this.keyboardScrollConfig = const KeyboardScrollConfig(),
    this.customMouseWheelScrollConfig = const CustomMouseWheelScrollConfig(),
    this.onScroll,
    this.onMMBScrollStateChanged,
    this.onMMBScrollCursorPositionUpdate,
    required this.child,
  }) : super(key: key);

  /// Scrollable child widget
  final Widget child;

  /// The scroll controller must also be supplied
  /// to the wrapped scrollable widget.
  ///
  /// They must use the same controller
  final ScrollController scrollController;

  /// Enables scrolling using the middle mouse button (MMB), in two ways:
  /// 1. Tap MMB --> Drag MMB --> Tap MMB
  ///   or
  /// 2. Tap and hold MMB --> Drag MMB --> Release MMB
  final bool enableMMBScrolling;

  /// Configuration for middle mouse button scrolling
  final MMBScrollConfig mmbScrollConfig;

  /// Enables scrolling using theese keys:
  /// ```
  /// Arrows (up, down, left, right)
  /// Space (+ Shift)
  /// PageUp, PageDown
  /// ```
  final bool enableKeyboardScrolling;

  /// Configuration for keyboard scrolling
  final KeyboardScrollConfig keyboardScrollConfig;

  /// Enables scrolling the view programatically when using mouse wheel
  /// This is done using a scroll listener
  ///
  /// Useful in cases when using NeverScrollableScrollPhysics
  /// on the wrapped scrollable widget
  final bool enableCustomMouseWheelScrolling;

  /// Configuration for programatically scrolling using mouse wheel
  final CustomMouseWheelScrollConfig customMouseWheelScrollConfig;

  /// Callback which fires when the wrapped scrollable's scroll offset changes
  final void Function(double offset)? onScroll;

  /// Callback which fires when the MMB scrolling state is changed
  final void Function(bool scrollingActive)? onMMBScrollStateChanged;

  /// Callback which fires when the MMB scrolling
  /// cursor's local position changes
  final void Function(
    Offset localCursorOffset,
    MMBScrollCursorActivity cursorScrollActivity,
  )? onMMBScrollCursorPositionUpdate;

  @override
  _ImprovedScrollingState createState() => _ImprovedScrollingState();
}

class _ImprovedScrollingState extends State<ImprovedScrolling> {
  ScrollController get scrollController => widget.scrollController;
  bool get isVerticalAxis => scrollController.position.axis == Axis.vertical;

  final _middleMouseButtonId = 4;
  var _mmbScrollCursorActivity = MMBScrollCursorActivity.idle;
  var _mmbScrollActive = false;
  var _mmbScrollCurrentCursorPosition = Offset.zero;
  var _mmbScrollLastCursorStartPosition = Offset.zero;
  var _mmbScrollLastVelocity = Offset.zero;
  Timer? _mmbScrollingTimer;

  final _keyboardScrollFocusNode = FocusNode();
  var _isShiftPressedDown = false;
  double _lastScrollDestPos = 0.0;

  late final Throttler mouseWheelForwardThrottler;
  late final Throttler mouseWheelBackwardThrottler;

  bool get isMMBScrollTimerActive =>
      _mmbScrollingTimer != null && _mmbScrollingTimer!.isActive;

  double get mmbScrollNextAutoScrollAcceleration {
    final lastVelocityByAxis =
        isVerticalAxis ? _mmbScrollLastVelocity.dy : _mmbScrollLastVelocity.dx;
    return lastVelocityByAxis.abs() / widget.mmbScrollConfig.decelerationForce;
  }

  MouseCursor get mmbScrollMouseCursor {
    if (widget.enableMMBScrolling && _mmbScrollActive) {
      if (widget.mmbScrollConfig.customScrollCursor != null) {
        return SystemMouseCursors.none;
      }

      switch (_mmbScrollCursorActivity) {
        case MMBScrollCursorActivity.idle:
          return SystemMouseCursors.move;
        case MMBScrollCursorActivity.scrollingUp:
          return SystemMouseCursors.resizeUp;
        case MMBScrollCursorActivity.scrollingDown:
          return SystemMouseCursors.resizeDown;
        case MMBScrollCursorActivity.scrollingLeft:
          return SystemMouseCursors.resizeLeft;
        case MMBScrollCursorActivity.scrollingRight:
          return SystemMouseCursors.resizeRight;
      }
    }
    return MouseCursor.defer;
  }

  @override
  void initState() {
    super.initState();
    mouseWheelForwardThrottler = Throttler(
      widget.customMouseWheelScrollConfig.mouseWheelTurnsThrottleTimeMs,
    );
    mouseWheelBackwardThrottler = Throttler(
      widget.customMouseWheelScrollConfig.mouseWheelTurnsThrottleTimeMs,
    );
    scrollController.addListener(scrollControllerListener);
    _lastScrollDestPos = scrollController.initialScrollOffset;
  }

  void scrollControllerListener() {
    widget.onScroll?.call(scrollController.offset);
  }

  void setMMBScrollActive(bool value) {
    if (_mmbScrollActive == value) {
      return;
    }

    setState(() {
      _mmbScrollActive = value;
    });
  }

  void setMMBScrollCursorStartScrollPosition(Offset position) {
    setState(() {
      _mmbScrollLastCursorStartPosition = position;
    });
  }

  void setMMBScrollCursorPosition(Offset position) {
    setState(() {
      _mmbScrollCurrentCursorPosition = position;
    });
  }

  void setMMBScrollCursorActivity(MMBScrollCursorActivity mmbCursorActivity) {
    if (_mmbScrollCursorActivity == mmbCursorActivity) {
      return;
    }

    setState(() {
      _mmbScrollCursorActivity = mmbCursorActivity;
    });
  }

  void setMMBScrollVelocity(Offset offset) {
    // setState() is not necessary here because
    // this is not used inside the build() method
    _mmbScrollLastVelocity = offset;
  }

  void updateMMBScrollVelocity(Offset offset) {
    // setState() is not necessary here because
    // this is not used inside the build() method
    _mmbScrollLastVelocity += offset;
  }

  void setShiftPressedDown(bool value) {
    // setState() is not necessary here because
    // this is not used inside the build() method
    _isShiftPressedDown = value;
  }

  void mmbScrollBy(Offset delta) {
    if (!_mmbScrollActive) {
      return;
    }
    final currentOffset = scrollController.offset;

    final scrollDeltaByAxis = isVerticalAxis ? delta.dy : delta.dx;
    final newScrollOffset =
        currentOffset + scrollDeltaByAxis * mmbScrollNextAutoScrollAcceleration;

    final minScrollExtent = scrollController.position.minScrollExtent;
    final maxScrollExtent = scrollController.position.maxScrollExtent;

    // Only allow scrolling within the scrollable boundaries
    if (newScrollOffset <= minScrollExtent) {
      scrollController.jumpTo(minScrollExtent);
    } else if (newScrollOffset >= maxScrollExtent) {
      scrollController.jumpTo(maxScrollExtent);
    } else {
      scrollController.jumpTo(newScrollOffset);
    }
  }

  void performMMBAutoScrolling(PointerEvent event) {
    // Theese will always happen in order to
    // update the current cursor and velocity
    setMMBScrollCursorPosition(event.localPosition);
    updateMMBScrollVelocity(event.delta);

    widget.onMMBScrollCursorPositionUpdate?.call(
      _mmbScrollCurrentCursorPosition,
      _mmbScrollCursorActivity,
    );

    // If the timer is already running for
    // either `onPointerMove` or `onPointerHover` then return
    if (isMMBScrollTimerActive) {
      return;
    }

    _mmbScrollingTimer =
        Timer.periodic(widget.mmbScrollConfig.autoScrollDelay, (timer) {
      // Everything here is computed after this
      // callback is scheduled (in the future)

      // First check if the cursor is idle (is inside the start area)
      final lastStartCursorPosByAxis = isVerticalAxis
          ? _mmbScrollLastCursorStartPosition.dy
          : _mmbScrollLastCursorStartPosition.dx;

      final currentCursorPosByAxis = isVerticalAxis
          ? _mmbScrollCurrentCursorPosition.dy
          : _mmbScrollCurrentCursorPosition.dx;

      final cursorIsWhereTheScrollStartedArea = currentCursorPosByAxis >
              lastStartCursorPosByAxis -
                  widget.mmbScrollConfig.idleCursorAreaSize / 2 &&
          currentCursorPosByAxis <
              lastStartCursorPosByAxis +
                  widget.mmbScrollConfig.idleCursorAreaSize / 2;

      if (cursorIsWhereTheScrollStartedArea) {
        //
        // If the cursor is idle, change it's type to idle
        setMMBScrollCursorActivity(MMBScrollCursorActivity.idle);
      } else {
        //
        // Else compute the next auto scrolling velocity using a percent of
        // the last velocity for an incremental scrolling effect.
        final scrollingVelocity = event.delta +
            _mmbScrollLastVelocity *
                widget.mmbScrollConfig.velocityBackpropagationPercent;

        if (isVerticalAxis) {
          if (scrollingVelocity.dy > _mmbScrollLastVelocity.dy) {
            setMMBScrollCursorActivity(MMBScrollCursorActivity.scrollingUp);
          } else {
            setMMBScrollCursorActivity(MMBScrollCursorActivity.scrollingDown);
          }
        } else {
          if (scrollingVelocity.dx > _mmbScrollLastVelocity.dx) {
            setMMBScrollCursorActivity(MMBScrollCursorActivity.scrollingLeft);
          } else {
            setMMBScrollCursorActivity(MMBScrollCursorActivity.scrollingRight);
          }
        }

        mmbScrollBy(scrollingVelocity);
      }

      // The timer will stop when MMB scrolling is active and
      // one of `onPointerDown` or `onPointerUp` events gets triggered
      if (!_mmbScrollActive) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    if (isMMBScrollTimerActive) {
      _mmbScrollingTimer!.cancel();
    }
    scrollController.removeListener(scrollControllerListener);
    _keyboardScrollFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;

    child = Listener(
      onPointerDown: (event) {
        // Set the initial local position, cursor type and velocity
        // Triggers only when the input type is mouse and the button is MMB
        if (widget.enableMMBScrolling &&
            event.kind == PointerDeviceKind.mouse &&
            event.buttons == _middleMouseButtonId) {
          setMMBScrollActive(!_mmbScrollActive);
          setMMBScrollCursorStartScrollPosition(event.localPosition);
          setMMBScrollCursorPosition(event.localPosition);
          setMMBScrollVelocity(event.localDelta);
          setMMBScrollCursorActivity(MMBScrollCursorActivity.idle);

          widget.onMMBScrollStateChanged?.call(_mmbScrollActive);
          widget.onMMBScrollCursorPositionUpdate?.call(
            _mmbScrollCurrentCursorPosition,
            _mmbScrollCursorActivity,
          );
        }
      },
      onPointerMove: (event) {
        if (widget.enableMMBScrolling && _mmbScrollActive) {
          performMMBAutoScrolling(event);
        }
      },
      onPointerHover: (event) {
        if (widget.enableMMBScrolling && _mmbScrollActive) {
          performMMBAutoScrolling(event);
        }

        if (widget.enableKeyboardScrolling &&
            !_keyboardScrollFocusNode.hasFocus &&
            event.kind == PointerDeviceKind.mouse) {
          // Request focus in order to be able to use keyboard keys
          FocusScope.of(context).requestFocus(_keyboardScrollFocusNode);
        }
      },
      onPointerUp: (event) {
        // When releasing the button, if the timer is still
        // running then cancel timer and stop the MMB scrolling
        if (isMMBScrollTimerActive) {
          setMMBScrollActive(false);
          _mmbScrollingTimer!.cancel();

          widget.onMMBScrollStateChanged?.call(false);
          widget.onMMBScrollCursorPositionUpdate?.call(
            _mmbScrollCurrentCursorPosition,
            _mmbScrollCursorActivity,
          );
        } else {
          _lastScrollDestPos = scrollController.offset;
        }
      },
      onPointerPanZoomUpdate: (event) {
        if (widget.enableCustomMouseWheelScrolling &&
            event.kind == PointerDeviceKind.trackpad) {
          if (!isVerticalAxis && !_isShiftPressedDown) {
            return;
          }
          final delta = Offset(event.panDelta.dx, -event.panDelta.dy);
          final scrollDelta = delta.dy;

          final newOffset = scrollController.offset +
              scrollDelta *
                  widget.customMouseWheelScrollConfig.scrollAmountMultiplier;

          if (scrollDelta.isNegative) {
            scrollJumpTo(math.max(0.0, newOffset));
          } else {
            scrollJumpTo(
                math.min(scrollController.position.maxScrollExtent, newOffset));
          }
        }
      },
      onPointerSignal: (event) {
        if (widget.enableCustomMouseWheelScrolling &&
            event is PointerScrollEvent &&
            event.kind == PointerDeviceKind.mouse) {
          if (!isVerticalAxis && !_isShiftPressedDown) {
            return;
          }

          final duration = widget.customMouseWheelScrollConfig.scrollDuration;
          final curve = widget.customMouseWheelScrollConfig.scrollCurve;
          // Work-around for a Flutter issue regarding horizontal scrolling
          //
          // Basically `event.scrollDelta.dx` should return +-33.3333
          // (the default scroll amount) but it returns 0.0, so we must
          // use `event.scrollDelta.dy` instead (which should actually
          // return 0.0 now, but it actually returns +-33.3333,
          // which means they are somehow inverted)
          final scrollDelta = event.scrollDelta.dy;

          final newOffset = math.max(
                  0,
                  math.min(
                    scrollController.position.maxScrollExtent,
                    _lastScrollDestPos,
                  )) +
              scrollDelta *
                  widget.customMouseWheelScrollConfig.scrollAmountMultiplier;
          startTransformedScroll(
              newOffset, scrollDelta.isNegative, curve, duration);
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: child,
          ),
          if (widget.enableMMBScrolling &&
              widget.mmbScrollConfig.customScrollCursor != null &&
              _mmbScrollActive)
            Positioned(
              top: _mmbScrollCurrentCursorPosition.dy -
                  widget.mmbScrollConfig.customScrollCursor!.size / 2,
              left: _mmbScrollCurrentCursorPosition.dx -
                  widget.mmbScrollConfig.customScrollCursor!.size / 2,
              child: SizedBox(
                height: widget.mmbScrollConfig.customScrollCursor!.size,
                width: widget.mmbScrollConfig.customScrollCursor!.size,
                child: buildMMBScrollingCustomCursor(
                  widget.mmbScrollConfig.customScrollCursor!,
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.enableMMBScrolling) {
      child = MouseRegion(
        cursor: mmbScrollMouseCursor,
        child: child,
      );
    }

    if (widget.enableKeyboardScrolling) {
      final arrowsScrollAmount = widget.keyboardScrollConfig.arrowsScrollAmount;
      final arrowsScrollDuration =
          widget.keyboardScrollConfig.arrowsScrollDuration;
      final pageUpDownScrollAmount =
          widget.keyboardScrollConfig.pageUpDownScrollAmount;
      final pageUpDownScrollDuration =
          widget.keyboardScrollConfig.pageUpDownScrollDuration;
      final spaceScrollAmount = widget.keyboardScrollConfig.spaceScrollAmount;
      final spaceScrollDuration =
          widget.keyboardScrollConfig.spaceScrollDuration;
      final homeScrollDurationBuilder =
          widget.keyboardScrollConfig.homeScrollDurationBuilder;
      final endScrollDurationBuilder =
          widget.keyboardScrollConfig.endScrollDurationBuilder;
      final defaultHomeEndScrollDuration =
          widget.keyboardScrollConfig.defaultHomeEndScrollDuration;
      final curve = widget.keyboardScrollConfig.scrollCurve;

      child = RawKeyboardListener(
        focusNode: _keyboardScrollFocusNode,
        onKey: (event) {
          if (isVerticalAxis) {
            if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
              scrollController.animateTo(
                scrollController.offset + arrowsScrollAmount,
                duration: arrowsScrollDuration,
                curve: curve,
              );
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
              scrollController.animateTo(
                scrollController.offset - arrowsScrollAmount,
                duration: arrowsScrollDuration,
                curve: curve,
              );
            } else if (event.isKeyPressed(LogicalKeyboardKey.pageUp)) {
              scrollController.animateTo(
                scrollController.offset - pageUpDownScrollAmount,
                duration: pageUpDownScrollDuration,
                curve: curve,
              );
            } else if (event.isKeyPressed(LogicalKeyboardKey.pageDown)) {
              scrollController.animateTo(
                scrollController.offset + pageUpDownScrollAmount,
                duration: pageUpDownScrollDuration,
                curve: curve,
              );
            } else if (event.isShiftPressed &&
                event.isKeyPressed(LogicalKeyboardKey.space)) {
              scrollController.animateTo(
                scrollController.offset - spaceScrollAmount,
                duration: spaceScrollDuration,
                curve: curve,
              );
            } else if (event.isKeyPressed(LogicalKeyboardKey.space)) {
              scrollController.animateTo(
                scrollController.offset + spaceScrollAmount,
                duration: spaceScrollDuration,
                curve: curve,
              );
            } else if (event.isKeyPressed(LogicalKeyboardKey.home)) {
              scrollController.animateTo(
                scrollController.position.minScrollExtent,
                duration: homeScrollDurationBuilder?.call(
                      scrollController.offset,
                      scrollController.position.minScrollExtent,
                    ) ??
                    defaultHomeEndScrollDuration,
                curve: curve,
              );
            } else if (event.isKeyPressed(LogicalKeyboardKey.end)) {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: endScrollDurationBuilder?.call(
                      scrollController.offset,
                      scrollController.position.maxScrollExtent,
                    ) ??
                    defaultHomeEndScrollDuration,
                curve: curve,
              );
            }
          } else {
            //
            // When direction is horizontal, only allow
            // left and right arrow keys and shift-scrolling
            if (event.isShiftPressed != _isShiftPressedDown) {
              setShiftPressedDown(event.isShiftPressed);
            }

            if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
              scrollController.animateTo(
                scrollController.offset - arrowsScrollAmount,
                duration: arrowsScrollDuration,
                curve: curve,
              );
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
              scrollController.animateTo(
                scrollController.offset + arrowsScrollAmount,
                duration: arrowsScrollDuration,
                curve: curve,
              );
            }
          }
        },
        child: child,
      );
    }
    return child;
  }

  Widget buildMMBScrollingCustomCursor(CustomScrollCursor cursor) {
    switch (_mmbScrollCursorActivity) {
      case MMBScrollCursorActivity.idle:
        return cursor.idle;
      case MMBScrollCursorActivity.scrollingUp:
        return cursor.scrollingUp;
      case MMBScrollCursorActivity.scrollingDown:
        return cursor.scrollingDown;
      case MMBScrollCursorActivity.scrollingLeft:
        return cursor.scrollingLeft;
      case MMBScrollCursorActivity.scrollingRight:
        return cursor.scrollingRight;
    }
  }

  void startTransformedScroll(
    double newOffset,
    bool isNegative,
    Curve curve,
    Duration duration,
  ) {
    if (isNegative) {
      mouseWheelForwardThrottler.run(() {
        scrollAnimateTo(
          math.max(0.0, newOffset),
          duration: duration,
          curve: curve,
        );
      });
    } else {
      mouseWheelBackwardThrottler.run(() {
        scrollAnimateTo(
          math.min(scrollController.position.maxScrollExtent, newOffset),
          duration: duration,
          curve: curve,
        );
      });
    }
  }

  void scrollAnimateTo(
    double newOffset, {
    required Duration duration,
    required Curve curve,
  }) {
    // prevent window change, update when start scroll
    _lastScrollDestPos = math.max(
        0,
        math.min(
          scrollController.position.maxScrollExtent,
          _lastScrollDestPos,
        ));
    scrollController.jumpTo(_lastScrollDestPos);
    scrollController.animateTo(
      math.min(scrollController.position.maxScrollExtent, newOffset),
      duration: duration,
      curve: curve,
    );
    _lastScrollDestPos = newOffset;
  }

  void scrollJumpTo(double newOffset) {
    _lastScrollDestPos = math.max(
        0,
        math.min(
          scrollController.position.maxScrollExtent,
          newOffset,
        ));
    scrollController.jumpTo(_lastScrollDestPos);
  }
}
