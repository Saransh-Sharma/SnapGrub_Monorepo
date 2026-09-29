import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapgrub/app/e2e/e2e_ids.dart';
import 'package:snapgrub/app/shell/app_shell.dart';
import 'package:snapgrub/app/theme/design_tokens.dart';
import 'package:snapgrub/core/design_system/design_system.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

/// Standard chrome for secondary (drill-in) screens.
///
/// The leading control is decided by where the screen sits, never by its
/// title:
/// * the route can pop → back arrow that pops (restores swipe-back),
/// * the screen is a tab root inside the app shell → no leading control,
/// * otherwise (deep link / `go`) → back to [backLocation], or a Home icon
///   when [backLocation] is `/home`.
class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    this.actions,
    this.backLocation = '/home',
    this.onBack,
    this.e2eId,
    this.padding,
    this.showSyncBanner = true,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  /// Fallback destination when there is nothing to pop.
  final String backLocation;

  /// Overrides the leading control's action (e.g. an unsaved-changes guard).
  final VoidCallback? onBack;

  /// Stable test id. Defaults to the legacy `scaffold.<title_slug>` so
  /// existing E2E flows keep working; new screens should pass it explicitly.
  final String? e2eId;

  /// Body padding; defaults to the standard page gutter.
  final EdgeInsetsGeometry? padding;

  /// Screens that *are* the sync surface hide the banner that links to it.
  final bool showSyncBanner;

  static String legacyId(String title) =>
      'scaffold.${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final syncStatus =
        ref.watch(syncControllerProvider).valueOrNull ?? SyncStatus.idle;
    final inShell = StatefulNavigationShell.maybeOf(context) != null;
    final leading = _leading(context, inShell: inShell);

    Widget body = child;
    if (inShell) {
      // Let scrollables (which read MediaQuery padding) clear the floating
      // tab bar without every screen knowing about it.
      final media = MediaQuery.of(context);
      body = MediaQuery(
        data: media.copyWith(
          padding:
              media.padding.copyWith(bottom: AppShell.bottomInset(context)),
        ),
        child: body,
      );
    }

    return E2eId(
      id: e2eId ?? legacyId(title),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: leading,
          titleSpacing: leading == null
              ? SnapGrubDesignTokens.space20
              : SnapGrubDesignTokens.space4,
          title: Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          actions: actions,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: .74),
                  border: Border(
                    bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: .55),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: PremiumBackdrop(
          child: SafeArea(
            top: false,
            bottom: !inShell,
            child: Column(
              children: [
                if (showSyncBanner)
                  AnimatedSize(
                    duration: SgMotion.of(context).settle,
                    curve: SgMotion.of(context).standard,
                    alignment: Alignment.topCenter,
                    child: _SyncBanner.visibleFor(syncStatus)
                        ? _SyncBanner(status: syncStatus)
                        : const SizedBox(width: double.infinity),
                  ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: SnapGrubDesignTokens.maxContentWidth,
                      ),
                      child: Padding(
                        padding: padding ??
                            const EdgeInsets.fromLTRB(
                              SnapGrubDesignTokens.space16,
                              SnapGrubDesignTokens.space12,
                              SnapGrubDesignTokens.space16,
                              0,
                            ),
                        child: body,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _leading(BuildContext context, {required bool inShell}) {
    final router = GoRouter.maybeOf(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (canPop) {
      return _LeadingButton(
        icon: Icons.arrow_back_rounded,
        tooltip: 'Back',
        // maybePop respects PopScope (e.g. unsaved-changes guards).
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }
    if (inShell) return null;
    final home = backLocation == '/home';
    return _LeadingButton(
      icon: home ? Icons.home_rounded : Icons.arrow_back_rounded,
      tooltip: home ? 'Home' : 'Back',
      onPressed: onBack ?? () => router?.go(backLocation),
    );
  }
}

class _LeadingButton extends StatelessWidget {
  const _LeadingButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // The id is kept as `nav.home` for both variants: E2E flows use it as
    // "leave this screen".
    return E2eId(
      id: 'nav.home',
      child: IconButton(
        tooltip: tooltip,
        onPressed: () {
          SgHaptics.tap();
          onPressed();
        },
        icon: Icon(icon),
      ),
    );
  }
}

/// A thin, human status strip shown only while something isn't synced.
class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.status});

  final SyncStatus status;

  static bool visibleFor(SyncStatus status) =>
      status == SyncStatus.pending ||
      status == SyncStatus.syncing ||
      status == SyncStatus.failed ||
      status == SyncStatus.conflict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.sg;
    final (icon, label, tone) = switch (status) {
      SyncStatus.syncing => (
          Icons.sync_rounded,
          'Syncing…',
          StatusTone.info,
        ),
      SyncStatus.pending => (
          Icons.cloud_upload_outlined,
          'Saved on your phone. Syncing soon.',
          StatusTone.neutral,
        ),
      SyncStatus.failed => (
          Icons.sync_problem_rounded,
          'Some changes didn’t sync. Tap to fix.',
          StatusTone.attention,
        ),
      SyncStatus.conflict => (
          Icons.rule_rounded,
          'A change needs review.',
          StatusTone.attention,
        ),
      _ => (Icons.cloud_done_outlined, 'All synced', StatusTone.positive),
    };
    final color = switch (tone) {
      StatusTone.neutral => theme.colorScheme.onSurfaceVariant,
      StatusTone.positive => tokens.success,
      StatusTone.attention => tokens.warning,
      StatusTone.info => tokens.info,
    };
    return E2eId(
      id: 'sync.banner.${status.name}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SnapGrubDesignTokens.space16,
          SnapGrubDesignTokens.space8,
          SnapGrubDesignTokens.space16,
          0,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: SnapGrubDesignTokens.maxContentWidth,
          ),
          child: Material(
            color: color.withValues(alpha: .12),
            borderRadius:
                BorderRadius.circular(SnapGrubDesignTokens.radiusPill),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                SgHaptics.tap();
                GoRouter.maybeOf(context)?.push('/sync');
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: SnapGrubDesignTokens.minTapTarget - 8,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SnapGrubDesignTokens.space16,
                    vertical: SnapGrubDesignTokens.space8,
                  ),
                  child: Row(
                    children: [
                      Icon(icon,
                          size: SnapGrubDesignTokens.iconSm, color: color),
                      const SizedBox(width: SnapGrubDesignTokens.space8),
                      Expanded(
                        child: Text(
                          label,
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: SnapGrubDesignTokens.iconMd,
                        color: color,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A calm list row for settings-style screens: tinted icon badge, title,
/// optional subtitle and trailing widget. Used by privacy, sync and library
/// screens so they share one rhythm.
class AppRow extends StatelessWidget {
  const AppRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.showChevron,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  /// Defaults to true when the row is tappable and has no [trailing].
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = destructive ? scheme.error : scheme.primary;
    final badge = destructive
        ? scheme.errorContainer.withValues(alpha: .6)
        : context.sg.energy.soft;
    final chevron = showChevron ?? (onTap != null && trailing == null);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(SnapGrubDesignTokens.radiusSm),
        onTap: onTap == null
            ? null
            : () {
                SgHaptics.tap();
                onTap!();
              },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: SnapGrubDesignTokens.minTapTarget + 8,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SnapGrubDesignTokens.space12,
              vertical: SnapGrubDesignTokens.space12,
            ),
            child: Row(
              children: [
                Container(
                  width: SnapGrubDesignTokens.space40,
                  height: SnapGrubDesignTokens.space40,
                  decoration: BoxDecoration(
                    color: badge,
                    borderRadius:
                        BorderRadius.circular(SnapGrubDesignTokens.radiusXs),
                  ),
                  child: Icon(icon,
                      size: SnapGrubDesignTokens.iconMd, color: accent),
                ),
                const SizedBox(width: SnapGrubDesignTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: destructive ? scheme.error : null,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: SnapGrubDesignTokens.space8),
                  trailing!,
                ],
                if (chevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
