import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Navigation helpers that keep a real back stack.
extension SnapGrubNav on BuildContext {
  /// Pops when possible, otherwise goes to [fallback] (e.g. after a deep link).
  void popOrGo(String fallback, [Object? result]) {
    if (canPop()) {
      pop(result);
    } else {
      go(fallback);
    }
  }

  /// Opens a drill-in screen on top of the current one.
  Future<T?> open<T extends Object?>(String location, {Object? extra}) =>
      push<T>(location, extra: extra);

  /// Replaces the current screen in a chained flow (capture → review) so
  /// Back returns to where the flow started.
  void continueTo(String location, {Object? extra}) {
    if (canPop()) {
      pushReplacement(location, extra: extra);
    } else {
      go(location, extra: extra);
    }
  }
}
