import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

import 'custom_scroll_cursor.dart';

/// Middle mouse button scrolling configuration
class MMBScrollConfig {
  /// Default values
  const MMBScrollConfig({
    this.customScrollCursor,
    this.idleCursorAreaSize = 30.0,
    this.autoScrollDelay = Duration.zero,
    this.velocityBackpropagationPercent = 30.0 / 100.0,
    this.decelerationForce = 500.0,
  });

  /// Custom cursor specified by the user
  ///
  /// If null, default system cursors will be used instead
  final CustomScrollCursor? customScrollCursor;

  /// Size of the area where the cursor changes to idle
  /// This gets split in half (one half up, one half down)
  final double idleCursorAreaSize;

  /// The delay between sequential auto scrolls.
  ///
  /// Affects scrolling framerate (higher delay = more staggered/laggy scrolling)
  final Duration autoScrollDelay;

  /// Percent of how much speed to extract from the
  /// last scrolling's velocity and add to the next velocity
  ///
  /// Affects speed
  final double velocityBackpropagationPercent;

  /// Amount of friction
  ///
  /// Affects how smooth to initiate the scrolling when getting out
  /// of the idle zone, but will also affect overall speed
  ///
  /// A lower value will make the scrolling start abruptly,
  /// while a higher value will make it smooth
  final double decelerationForce;
}

/// Keyboard scrolling configuration
class KeyboardScrollConfig {
  /// Default values
  const KeyboardScrollConfig({
    this.arrowsScrollAmount = 200.0,
    this.arrowsScrollDuration = const Duration(milliseconds: 200),
    this.pageUpDownScrollAmount = 500.0,
    this.pageUpDownScrollDuration = const Duration(milliseconds: 200),
    this.spaceScrollAmount = 600.0,
    this.spaceScrollDuration = const Duration(milliseconds: 200),
    this.defaultHomeEndScrollDuration = const Duration(milliseconds: 500),
    this.homeScrollDurationBuilder,
    this.endScrollDurationBuilder,
    this.scrollCurve = Curves.easeOutCubic,
  });

  /// Amount to scroll when pressing arrow keys
  final double arrowsScrollAmount;

  /// Duration to reach the new scroll position when using arrow keys
  final Duration arrowsScrollDuration;

  /// Amount to scroll when pressing page up/down
  final double pageUpDownScrollAmount;

  /// Duration to reach the new scroll position when using page up/down
  final Duration pageUpDownScrollDuration;

  /// Amount to scroll when pressing space
  final double spaceScrollAmount;

  /// Duration to reach the new scroll position when using space
  final Duration spaceScrollDuration;

  /// Compute duration to reach the start of the scroll view
  /// based on where the scroll offset is right now
  final Duration Function(
    double currentScrollOffset,
    double minScrollOffset,
  )? homeScrollDurationBuilder;

  /// Compute duration to reach the end of the scroll view
  /// based on where the scroll offset is right now
  final Duration Function(
    double currentScrollOffset,
    double maxScrollOffset,
  )? endScrollDurationBuilder;

  /// Default duration for home and end scrolling
  final Duration defaultHomeEndScrollDuration;

  /// Scroll curve
  final Curve scrollCurve;
}

/// Custom mouse wheel scrolling configuration
class CustomMouseWheelScrollConfig {
  /// Default values
  const CustomMouseWheelScrollConfig({
    this.scrollAmountMultiplier = 3.0,
    this.scrollDuration = const Duration(milliseconds: 400),
    this.scrollCurve = Curves.linearToEaseOut,
    this.mouseWheelTurnsThrottleTimeMs = 80,
  });

  /// Extra amount to scroll when scrolling using mouse wheel
  ///
  /// Can be negative
  final double scrollAmountMultiplier;

  /// Scroll duration
  final Duration scrollDuration;

  /// Scroll curve
  final Curve scrollCurve;

  /// Scrolling throttle duration
  final int mouseWheelTurnsThrottleTimeMs;
}
