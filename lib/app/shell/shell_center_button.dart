// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/search_fab_action_provider.dart';
import '../../l10n/app_localizations.dart';
import 'shell_bar_visibility.dart';
import 'shell_nav_item.dart';
import 'search_fab_tap.dart';

/// The app's primary action — the round button docked in the bottom
/// bar's notch.
///
/// Extracted from `ShellBottomBar` (#4097) for two reasons: the bar had
/// grown past the file-length cap, and this is where the swipe-away
/// feature's non-gesture escape hatch belongs, next to the button that
/// is the only chrome left on screen once the bar is hidden.
class ShellCenterButton extends ConsumerWidget {
  const ShellCenterButton({
    super.key,
    required this.items,
    required this.slot,
    required this.currentIndex,
    required this.iconControllers,
    required this.branchForSlot,
    required this.isLandscape,
    required this.onTap,
    this.action,
  });

  final List<ShellNavItem> items;

  /// This button's slot in the bar — the primary destination.
  final int slot;
  final int currentIndex;
  final List<AnimationController> iconControllers;
  final List<int> branchForSlot;
  final bool isLandscape;
  final ValueChanged<int> onTap;

  /// A registered context-aware action that overrides the default tap.
  final SearchFabAction? action;


  /// The raised, primary-tinted centre button for the core action.
  ///
  /// Portrait (#2552): the button docks into a concave notch carved into
  /// the bar's top edge (a CircularNotchedRectangle scallop, painted by
  /// the bar's [NotchedBarBorder] shape). The notch IS the seat — the bar
  /// surface curves up and embraces the button instead of a flat disc
  /// sitting behind it. Landscape has no head-room, so the button stays
  /// flat in the bar.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = slot;
    // A field cannot be promoted, so take a local the analyser can
    // narrow — the original read a parameter.
    final action = this.action;
    final theme = Theme.of(context);
    final selected = i == currentIndex;
    final item = items[i];
    final controller = iconControllers[branchForSlot[i]];
    final diameter = isLandscape ? 40.0 : 56.0;

    // #2113 — context-aware FAB. Default reads stay safe (no `watch`
    // here so a results refresh doesn't re-paint the whole bar) —
    // the read happens lazily inside `onTap`, when it matters.
    //
    // Behaviour matrix:
    //   1. On the Search branch (results screen): tap → open the
    //      criteria modal so the user can refine the active search.
    //   2. On any other branch WITH live results: tap → switch to
    //      the Search branch and show the existing results.
    //   3. On any other branch with NO results: tap → open the
    //      criteria modal directly so the user can start a search
    //      from anywhere (no detour through an empty results screen).
    //
    // A registered [SearchFabAction] (e.g. from a future criteria-
    // screen "fire search" hook) wins over all three branches —
    // pluggable extension point.
    final defaultIcon = selected ? item.filledIcon : item.outlinedIcon;
    final iconData = action?.icon ?? defaultIcon;
    final tooltipLabel = action?.tooltip ?? item.label;
    // #2131 — disabled override: dim the icon when the current
    // registrant says the action isn't ready (e.g. route tab with no
    // destination). Null action ⇒ default branch behaviour, always
    // enabled.
    // #2553 — the dim is contextual *affordance only* now; a disabled
    // (or stale) action no longer swallows the tap — see [onTapHandler].
    final actionEnabled = action?.enabled ?? true;

    // #2553 — a registered-but-DISABLED (or stale) action must never
    // produce a dead `() {}` no-op. Only an enabled action overrides the
    // tap; anything else (null OR disabled OR stale) FALLS BACK to the
    // default branch behaviour (#2113 three-branch matrix, implemented in
    // search_fab_tap.dart). Worst case the FAB opens criteria / jumps to
    // Search — it can never become a permanent dead hit-target.
    final onTapHandler = (action != null && actionEnabled)
        ? action.onTap
        : () => handleSearchFabDefaultTap(
              ref: ref,
              slot: i,
              currentIndex: currentIndex,
              onTap: onTap,
            );

    // #2131 — surface + icon both dim when the registered action is
    // disabled, mirroring Material's standard disabled-button look.
    final buttonColor = actionEnabled
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.38);
    final iconColor = actionEnabled
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onPrimary.withValues(alpha: 0.6);

    // #3548 — the app's heart must not read as a flat disc. Three layers
    // of depth, all derived from the theme so light/dark/eco stay
    // coherent:
    //   * a hairline surface-coloured ring in the CircleBorder side —
    //     a crisp seat separating the button from whatever scrolls
    //     beneath the notch;
    //   * a top-light gradient over the primary fill (painted by an Ink
    //     so the ripple stays above it) — the dome that makes the disc
    //     read as raised;
    //   * a soft primary-tinted glow under the Material's own key
    //     shadow — the professional "lifted" halo.
    // Disabled keeps the flat dimmed fill (no dome on a dead control).
    final ringColor = theme.colorScheme.surface;
    final gradient = actionEnabled
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(buttonColor, Colors.white, 0.22)!,
              buttonColor,
              Color.lerp(buttonColor, Colors.black, 0.14)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          )
        : null;

    // #4097 — the non-gesture way back. `Semantics.onLongPress` is
    // exposed to TalkBack and switch access as an ACTION, so a user who
    // cannot perform a drag can still show a hidden bar; the physical
    // long-press below is the same path for everyone else. Tap is
    // untouched, so nothing anyone does today changes.
    final l10n = AppLocalizations.of(context);
    final hidden = ref.watch(shellBarHiddenProvider);
    // Idempotent on purpose: the semantics action and the physical
    // long-press share one merged semantics node, so performing the
    // action invokes BOTH handlers. `set` to an explicit target — rather
    // than `toggle` — makes the second call a no-op instead of undoing
    // the first.
    Future<void> toggleBar() async {
      await ref.read(shellBarHiddenProvider.notifier).set(!hidden);
      if (!context.mounted) return;
      // `announce` is deprecated in favour of `sendAnnouncement` (Flutter
      // 3.35): same channel, multi-window safe.
      unawaited(SemanticsService.sendAnnouncement(
        View.of(context),
        hidden ? l10n.shellBarShownAnnounce : l10n.shellBarHiddenAnnounce,
        Directionality.of(context),
      ));
    }

    final button = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: actionEnabled
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: buttonColor,
        shape: CircleBorder(
          side: BorderSide(color: ringColor, width: isLandscape ? 2 : 2.5),
        ),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTapHandler,
            // #4103 — the long-press MUST share the InkWell's arena. As an
            // outer GestureDetector it competed with this tap for the same
            // pointer, so a finger resting a fraction too long toggled the
            // bar and the search never fired — "sometimes no longer
            // triggers a research". One recognizer set, disambiguated by
            // Flutter, and the ripple matches the gesture.
            onLongPress: () => unawaited(toggleBar()),
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: Center(
                child: action != null
                    ? Icon(
                        iconData,
                        size: isLandscape ? 22.0 : 28.0,
                        color: iconColor,
                      )
                    : ShellBounceIcon(
                        controller: controller,
                        selected: selected,
                        icon: iconData,
                        iconSize: isLandscape ? 22.0 : 28.0,
                        color: iconColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: tooltipLabel,
      button: true,
      selected: selected,
      hint: l10n.shellBarToggleHint,
      onLongPress: () => unawaited(toggleBar()),
      excludeSemantics: true,
      // #2552 — the notch in the bar (the [NotchedBarBorder] shape) is
      // the seat now, for both orientations; no separate cradle disc.
      child: Tooltip(
        message: tooltipLabel,
        child: button,
      ),
    );
  }
}
