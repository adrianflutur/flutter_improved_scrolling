import 'dart:math';

import 'package:flutter/material.dart';

/// Custom cursor widget interface
abstract class CustomScrollCursor {
  /// Size
  double get size;

  /// The widget to show when in `CursorScrollActivity.idle` state
  Widget get idle;

  /// The widget to show when in `CursorScrollActivity.scrollingUp` state
  Widget get scrollingUp;

  /// The widget to show when in `CursorScrollActivity.scrollingDown` state
  Widget get scrollingDown;

  /// The widget to show when in `CursorScrollActivity.scrollingLeft` state
  Widget get scrollingLeft;

  /// The widget to show when in `CursorScrollActivity.scrollingRight` state
  Widget get scrollingRight;
}

/// Default custom cursor widget implementation
class DefaultCustomScrollCursor implements CustomScrollCursor {
  /// Constructor
  const DefaultCustomScrollCursor({
    Color cursorColor = Colors.black,
    Color borderColor = Colors.black,
    Color backgroundColor = Colors.white,
  })  : _cursorColor = cursorColor,
        _borderColor = borderColor,
        _backgroundColor = backgroundColor;

  final Color _cursorColor;
  final Color _borderColor;
  final Color _backgroundColor;

  Widget _buildCursor({
    bool idle = false,
    required Widget icon,
  }) {
    return Container(
      decoration: idle
          ? BoxDecoration(
              color: _backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: _borderColor,
              ),
            )
          : null,
      child: icon,
    );
  }

  /// Size
  @override
  double get size => 28.0;

  /// The widget to show when in `CursorScrollActivity.idle` state
  @override
  Widget get idle => Transform.rotate(
        angle: 3 * pi / 4,
        child: _buildCursor(
          idle: true,
          icon: Icon(
            Icons.zoom_out_map,
            color: _cursorColor,
            size: size - 6.0,
          ),
        ),
      );

  /// The widget to show when in `CursorScrollActivity.scrollingUp` state
  @override
  Widget get scrollingUp => _buildCursor(
        icon: Icon(
          Icons.arrow_drop_up,
          color: _cursorColor,
          size: size,
        ),
      );

  /// The widget to show when in `CursorScrollActivity.scrollingDown` state
  @override
  Widget get scrollingDown => Transform.rotate(
        angle: pi,
        child: scrollingUp,
      );

  /// The widget to show when in `CursorScrollActivity.scrollingLeft` state
  @override
  Widget get scrollingLeft => Transform.rotate(
        angle: -pi / 2,
        child: scrollingUp,
      );

  /// The widget to show when in `CursorScrollActivity.scrollingRight` state
  @override
  Widget get scrollingRight => Transform.rotate(
        angle: pi / 2,
        child: scrollingUp,
      );
}
