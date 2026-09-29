import 'dart:async';

import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/haptics.dart';

/// Shows a snackbar with an Undo action and a hairline countdown.
///
/// The destructive work is *deferred*: [commit] runs only after the window
/// closes without Undo. [onUndo] runs if the user taps Undo, which should
/// restore any optimistic UI change made before calling this.
Future<bool> showUndoSnackBar(
  BuildContext context, {
  required String message,
  required Future<void> Function() commit,
  VoidCallback? onUndo,
  Duration window = const Duration(seconds: 5),
  IconData icon = Icons.check_circle_rounded,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    await commit();
    return false;
  }
  var undone = false;
  messenger.hideCurrentSnackBar();
  final controller = messenger.showSnackBar(
    SnackBar(
      duration: window,
      padding: EdgeInsets.zero,
      content: _UndoContent(message: message, icon: icon, window: window),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          undone = true;
          SgHaptics.tick();
          onUndo?.call();
        },
      ),
    ),
  );
  await controller.closed;
  if (!undone) await commit();
  return undone;
}

/// Plain confirmation toast ("Duplicated", "Link copied").
void showSgToast(BuildContext context, String message,
    {IconData icon = Icons.check_circle_rounded}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.onInverseSurface),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

class _UndoContent extends StatelessWidget {
  const _UndoContent({
    required this.message,
    required this.icon,
    required this.window,
  });

  final String message;
  final IconData icon;
  final Duration window;

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onInverseSurface;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: on),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
        if (!reduce)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: window,
            builder: (context, value, _) => Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value,
                child: Container(height: 2, color: on.withValues(alpha: .35)),
              ),
            ),
          ),
      ],
    );
  }
}
