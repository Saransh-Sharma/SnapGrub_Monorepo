import 'package:flutter/material.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';

/// A card that groups settings rows with hairline dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      indent: 60,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .7),
    );
    return SgCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusMd),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) divider,
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One tappable settings row: leading icon, title, optional subtitle and
/// trailing widget (defaults to a chevron when tappable).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.e2eId,
    this.destructive = false,
    this.chevron = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? e2eId;
  final bool destructive;

  /// Shows a trailing chevron on tappable rows (hidden for actions).
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = destructive ? scheme.error : scheme.onSurface;
    // With large text, trailing status moves under the title so the title
    // keeps the full width instead of being squeezed.
    final stackTrailing =
        trailing != null && MediaQuery.textScalerOf(context).scale(10) > 14;
    Widget row = InkWell(
      onTap: onTap == null
          ? null
          : () {
              SgHaptics.tap();
              onTap!();
            },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: destructive
                      ? scheme.errorContainer.withValues(alpha: .6)
                      : scheme.primaryContainer.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: SnapGrubDesignTokens.iconMd,
                  color: destructive ? scheme.error : scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (stackTrailing) ...[
                      const SizedBox(height: 6),
                      trailing!,
                    ],
                  ],
                ),
              ),
              if (trailing != null && !stackTrailing) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
              if ((trailing == null || stackTrailing) &&
                  onTap != null &&
                  chevron) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
    row = Semantics(button: onTap != null, child: row);
    return e2eId == null ? row : E2eId(id: e2eId!, child: row);
  }
}

/// A labelled control block inside a settings group (segmented buttons,
/// pickers) with an optional explanatory line underneath.
class SettingsControl extends StatelessWidget {
  const SettingsControl({
    required this.title,
    required this.child,
    this.caption,
    this.e2eId,
    super.key,
  });

  final String title;
  final Widget child;
  final String? caption;
  final String? e2eId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          child,
          if (caption != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                caption!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
    return e2eId == null ? body : E2eId(id: e2eId!, child: body);
  }
}
