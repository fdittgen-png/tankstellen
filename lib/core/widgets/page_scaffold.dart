// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/shell/shell_bar_visibility.dart';

/// Bottom padding a scrollable body must reserve so its last row clears a
/// floating [FloatingActionButton] hosted by [PageScaffold.floatingActionButton]
/// (#2494).
///
/// Both the Carburant fill-up list and the Trajets trip list float their
/// "add" / "start recording" FAB over the list via the Scaffold FAB slot.
/// The Scaffold already lifts a floating FAB clear of the system bottom
/// inset, so callers must **not** add `MediaQuery.viewPadding.bottom` on
/// top of this — doing so double-counts the safe-area gap (the old
/// hand-rolled Trajets Stack bug). Use it as the list's
/// `EdgeInsets.only(bottom: kFabScrollClearance)`.
const double kFabScrollClearance = 96;

/// The bottom inset a scrollable inside a [PageScaffold] reserves (#4096).
///
/// Bodies run behind the shell's bottom bar now, so the bar's height
/// arrives as `MediaQuery.padding.bottom`. A list adds it to the FAB
/// clearance above: the content scrolls UNDER the bar as it should, and
/// the last row still clears both the bar and any floating button.
double shellScrollClearance(BuildContext context) =>
    kFabScrollClearance + MediaQuery.paddingOf(context).bottom;

/// Canonical outer chrome for every top-level screen — `Scaffold` +
/// `AppBar` + optional primary-tinted banner below the app bar + body.
///
/// Replaces the three competing "this is what this screen is about"
/// conventions identified in the #923 audit (plain app bar, banner
/// strip à la `ThemeSettingsScreen`, ad-hoc hero row). See
/// `docs/design/DESIGN_SYSTEM.md` §"PageScaffold" for the contract.
class PageScaffold extends ConsumerWidget {
  /// App-bar title. Used unless [titleWidget] is provided. Mutually
  /// exclusive with [titleWidget] — exactly one of the two must be
  /// non-null. Renders in the `pageTitle` role wrapped in
  /// `Semantics(header: true, …)`.
  final String? title;

  /// Custom title widget — escape hatch for screens whose title cannot
  /// be expressed as plain text (e.g. `StationDetailScreen`'s
  /// Hero-flighted brand-header composition). Mutually exclusive with
  /// [title]: pass exactly one. The caller is responsible for the
  /// title's semantics (header role, ellipsis, etc.) when this slot is
  /// used.
  final Widget? titleWidget;

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

  /// #4096 — every branch body runs behind the shell's bottom bar, so
  /// the docked button's notch shows CONTENT through it and the button
  /// reads as floating rather than sitting on a shelf. #4084 gave the Map
  /// this and it is the look the whole app should have.
  ///
  /// The bar's height arrives inside the body as
  /// `MediaQuery.padding.bottom`; a scrollable adds it to the clearance
  /// it already reserves so its last row still clears the bar, and the
  /// content scrolls UNDER the bar instead of stopping above it. Set
  /// this false only for a body that cannot tolerate painting there.
  final bool bodyBehindBottomBar;

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

  /// Optional [PreferredSizeWidget] below the app-bar title — e.g. a
  /// `TabBar` or `TabSwitcher`. Pass-through to [AppBar.bottom]. Used
  /// by tabbed screens (e.g. `FavoritesScreen`, `ConsumptionScreen`)
  /// that swap content via a [DefaultTabController] sibling to this
  /// scaffold.
  final PreferredSizeWidget? bottom;

  const PageScaffold({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.subtitle,
    this.bannerIcon,
    this.actions,
    this.bodyPadding,
    this.bodyBehindBottomBar = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.toolbarHeight,
    this.titleTextStyle,
    this.titleSpacing,
    this.bottomNavigationBar,
    this.bottom,
  })  : assert(
          title != null || titleWidget != null,
          'PageScaffold requires either `title` or `titleWidget` to be '
          'non-null.',
        ),
        assert(
          bannerIcon == null || title != null,
          'PageScaffold(bannerIcon: …) requires `title` (the banner '
          'shows the title text). Drop the banner or pass `title`.',
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // #4104 — the top chrome leaves with the bottom bar. "Maximum screen"
    // has to mean both ends, or the app bar keeps a sixth of the height
    // for a title the user is not reading. The status bar itself stays
    // (transparent, over the content — #4101): this hides the APP's
    // chrome, never the system's, and nothing enters immersive mode.
    final chromeHidden = ref.watch(shellBarHiddenProvider);
    final appBar = AppBar(
      title: titleWidget ?? Semantics(header: true, child: Text(title!)),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: toolbarHeight,
      titleTextStyle: titleTextStyle,
      titleSpacing: titleSpacing,
      bottom: bottom,
    );
    // The bar's own height PLUS the status-bar inset it pads itself with.
    // Both collapse together, which is why the Scaffold below is
    // `primary: false` — see [_CollapsingAppBar].
    final fullChromeHeight =
        appBar.preferredSize.height + MediaQuery.paddingOf(context).top;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: chromeHidden ? 0 : fullChromeHeight),
      duration: kShellBarHideDuration,
      curve: Curves.easeOutCubic,
      builder: (context, height, _) => _build(context, appBar, height),
    );
  }

  /// One frame of the collapse. `body`, `actions` and the rest are the
  /// same widget instances every frame, so Flutter short-circuits their
  /// subtrees and only the chrome's height actually re-lays-out.
  Widget _build(BuildContext context, AppBar appBar, double chromeHeight) {
    final effectivePadding = bodyPadding ?? Spacing.screenPadding;
    final collapsed = chromeHeight < 0.5;
    final scaffold = Scaffold(
      // The wrapper reports the TOTAL height including the status-bar
      // inset, so the Scaffold must not reserve that inset a second
      // time — otherwise a fully collapsed bar would leave a
      // status-bar-tall band behind.
      primary: false,
      appBar: collapsed
          ? null
          : _CollapsingAppBar(
              height: chromeHeight,
              naturalHeight:
                  appBar.preferredSize.height + MediaQuery.paddingOf(context).top,
              child: appBar,
            ),
      body: SafeArea(
        // With no app bar the body starts at y=0; keep it off the status
        // bar. While the bar is collapsing it still covers that strip.
        top: collapsed,
        bottom: false,
        child: Column(
          children: [
          if (bannerIcon != null)
            _PageBanner(
              icon: bannerIcon!,
              title: title!,
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
      ),
      // #4100 — the shell's bar lives on the OUTER Scaffold, so this
      // one's bottom edge is under it now that the body paints
      // full-bleed (#4096). The body SHOULD run behind the bar; a
      // floating button never should.
      floatingActionButton: floatingActionButton == null
          ? null
          : Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
              child: floatingActionButton,
            ),
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
    if (bodyBehindBottomBar) return scaffold;
    // Opted out: consume the bar's height so the body stops above it.
    return SafeArea(top: false, child: scaffold);
  }
}

/// An [AppBar] whose reported height can be animated to zero (#4104).
///
/// `Scaffold.appBar` lays out from `preferredSize`, so an app bar cannot
/// animate itself — the height has to come from above. This reports the
/// tween's current value while rendering the bar at its NATURAL height,
/// bottom-aligned and clipped, so the title and actions slide up under
/// the top edge instead of squashing.
///
/// [height] is the total including the status-bar inset, which is why
/// the [Scaffold] using this passes `primary: false`: the inset is
/// inside the number, and letting the Scaffold add it again would leave
/// a permanent band where the chrome used to be.
class _CollapsingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CollapsingAppBar({
    required this.height,
    required this.naturalHeight,
    required this.child,
  });

  final double height;
  final double naturalHeight;
  final Widget child;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        minHeight: naturalHeight,
        maxHeight: naturalHeight,
        child: child,
      ),
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
