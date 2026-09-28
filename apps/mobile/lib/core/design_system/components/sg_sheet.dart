import 'package:flutter/material.dart';
import 'package:snapgrub/core/design_system/haptics.dart';
import 'package:snapgrub/core/design_system/tokens.dart';

/// Opens a modal sheet with the SnapGrub chrome (handle, title, sticky
/// actions). Keyboard-aware and scrollable.
Future<T?> showSgSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  String? subtitle,
  Widget? actions,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
}) {
  SgHaptics.tap();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => SgSheetScaffold(
      title: title,
      subtitle: subtitle,
      actions: actions,
      child: builder(context),
    ),
  );
}

class SgSheetScaffold extends StatelessWidget {
  const SgSheetScaffold({
    required this.child,
    this.title,
    this.subtitle,
    this.actions,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                child: Semantics(
                  header: true,
                  child: Text(title!, style: theme.textTheme.headlineSmall),
                ),
              ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 2, 24, 8),
                child: Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: child,
              ),
            ),
            if (actions != null)
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: actions!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation sheet for destructive actions. Returns true when confirmed.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Keep it',
  IconData icon = Icons.delete_outline_rounded,
}) async {
  SgHaptics.warn();
  final result = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: scheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// A little grab-bag row used in sheets: icon, title, subtitle, tap.
class SgSheetAction extends StatelessWidget {
  const SgSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.onSurface;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: destructive
              ? scheme.errorContainer.withValues(alpha: .6)
              : context.sg.energy.soft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: () {
        SgHaptics.tap();
        onTap();
      },
    );
  }
}
