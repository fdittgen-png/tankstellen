import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Canonical outer chrome for every top-level screen — `Scaffold` +
/// `AppBar` + optional primary-tinted banner below the app bar + body.
///
/// Replaces the three competing "this is what this screen is about"
/// conventions identified in the #923 audit (plain app bar, banner
/// strip à la `ThemeSettingsScreen`, ad-hoc hero row). See
/// `docs/design/DESIGN_SYSTEM.md` §"PageScaffold" for the contract.
class PageScaffold extends StatelessWidget {
  /// App-bar title. Required — every page has a title in the
  /// `pageTitle` role.
  final String title;

  /// Optional subtitle — rendered inside the banner (if [bannerIcon]
  /// is set). When [bannerIcon] is null the subtitle is ignored
  /// because no dedicated slot exists for it — the app-bar title
  /// sits alone.
  final String? subtitle;

  /// When non-null, renders a primary-tinted banner strip directly
  /// under the app bar carrying the icon + [title] + [subtitle].
  /// Mirrors `ThemeSettingsScreen` / `PrivacyDashboardScreen`.
  final IconData? bannerIcon;

  /// Trailing app-bar actions. Every `IconButton` in this list must
  /// carry a `tooltip:` (enforced by
  /// `test/accessibility/icon_button_tooltip_coverage_test.dart`).
  final List<Widget>? actions;

  /// Screen body. Required. `PageScaffold` wraps it in
  /// [Padding] using [bodyPadding] and an [Expanded] so the body
  /// owns the remaining vertical space below the app bar (and banner,
  /// if any).
  final Widget body;

  /// Body padding. Defaults to `Spacing.screenPadding`
  /// (`EdgeInsets.all(16)`). Pass `EdgeInsets.zero` for full-bleed
  /// content (map screen).
  final EdgeInsets? bodyPadding;

  /// Optional FAB. Passed through to [Scaffold.floatingActionButton].
  final Widget? floatingActionButton;

  /// Optional FAB position. Passed through to
  /// [Scaffold.floatingActionButtonLocation]. Default `null` lets
  /// `Scaffold` pick its default (end-float). Use e.g.
  /// [FloatingActionButtonLocation.centerDocked] when pairing with a
  /// bottom bar.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Optional leading app-bar widget. Normally the back button — pass
  /// a custom drawer icon when needed.
  final Widget? leading;

  /// Whether the app bar shows its automatic leading. Default: true.
  final bool automaticallyImplyLeading;

  /// Optional override for the app-bar toolbar height. Pass-through to
  /// [AppBar.toolbarHeight]. Leave `null` to use the Material default.
  /// Compact screens (e.g. `SearchScreen` in landscape) shrink to ~40.
  final double? toolbarHeight;

  /// Optional override for the app-bar title text style. Pass-through to
  /// [AppBar.titleTextStyle]. Leave `null` to use the Material default.
  /// Compact screens (e.g. `MapScreen` in landscape) pass
  /// `TextStyle(fontSize: 16)`.
  final TextStyle? titleTextStyle;

  /// Optional override for the app-bar title spacing (horizontal space
  /// between the leading widget and the title). Pass-through to
  /// [AppBar.titleSpacing]. Leave `null` to use the Material default
  /// ([NavigationToolbar.kMiddleSpacing] = 16).
  final double? titleSpacing;

  /// Optional bottom bar — a pinned action bar below the body. Forwards
  /// to [Scaffold.bottomNavigationBar]. Used by form screens
  /// (e.g. `AddFillUpScreen`, `EditVehicleScreen`) to pin a Save button
  /// above the system nav inset without stealing scrollable real estate.
  final Widget? bottomNavigationBar;

  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.bannerIcon,
    this.actions,
    this.bodyPadding,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.toolbarHeight,
    this.titleTextStyle,
    this.titleSpacing,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = bodyPadding ?? Spacing.screenPadding;
    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(title)),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        toolbarHeight: toolbarHeight,
        titleTextStyle: titleTextStyle,
        titleSpacing: titleSpacing,
      ),
      body: Column(
        children: [
          if (bannerIcon != null)
            _PageBanner(
              icon: bannerIcon!,
              title: title,
              subtitle: subtitle,
            ),
          Expanded(
            child: Padding(
              padding: effectivePadding,
              child: body,
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Primary-tinted banner strip under the app bar.
///
/// Surface = `colorScheme.primaryContainer`; foreground =
/// `colorScheme.onPrimaryContainer`. Kept as a private widget so
/// every `PageScaffold(bannerIcon: …)` call lands on the same
/// visual shape without screens reinventing it.
class _PageBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _PageBanner({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.lg,
      ),
      color: theme.colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
