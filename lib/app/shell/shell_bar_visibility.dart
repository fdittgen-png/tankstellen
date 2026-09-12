// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/guarded.dart';
import '../../core/storage/storage_providers.dart';

part 'shell_bar_visibility.g.dart';

/// Whether the shell's bottom bar is swiped away (#4097).
///
/// Hiding it reveals the strip of content the bar was covering — bodies
/// already paint behind it since #4096 — and the round button stays
/// exactly where it is, so the one piece of chrome the user needs to get
/// the bar back is the one piece still on screen.
///
/// ## Never a trap
///
/// A hidden bar with no affordance is a dead end, so there are three
/// independent ways back and one of them is not a gesture:
///
///  1. an upward drag anywhere in the bottom strip,
///  2. a long-press on the round button,
///  3. the button's `Show navigation` semantics action, which switch
///     access and TalkBack reach without any gesture at all.
///
/// Tap keeps its current meaning, so nothing the user does today
/// changes.
///
/// The choice persists across launches — a user who wants the room
/// should not have to re-hide it every time — which is exactly why the
/// ways back have to be this redundant.
@Riverpod(keepAlive: true)
class ShellBarHidden extends _$ShellBarHidden {
  /// The `settings`-box key the preference persists under.
  static const String storageKey = 'shell_bottom_bar_hidden';

  @override
  bool build() {
    try {
      return ref.read(settingsStorageProvider).getSetting(storageKey) == true;
    } catch (e, st) {
      // A settings box that is not open yet (early startup, a widget
      // test) simply means "shown" — the safe state, since it is the one
      // that carries its own way out.
      logFailure(e, st, where: 'ShellBarHidden.build');
      return false;
    }
  }

  /// Hide or show the bar, persisting the choice.
  Future<void> set(bool hidden) async {
    if (state == hidden) return;
    state = hidden;
    try {
      await ref.read(settingsStorageProvider).putSetting(storageKey, hidden);
    } catch (e, st) {
      // The bar still moved; only the memory of it is lost.
      logFailure(e, st, where: 'ShellBarHidden.set');
    }
  }

  /// Swap the state — the long-press and semantics paths.
  Future<void> toggle() => set(!state);
}

/// How the hidden bar animates out, and back.
///
/// Long enough to read as the bar leaving rather than vanishing, short
/// enough that a user who hid it by accident is not waiting.
const Duration kShellBarHideDuration = Duration(milliseconds: 220);

/// The height the bar's row of tabs occupies, and therefore the height
/// the body gains when it slides away. Portrait only; landscape uses the
/// nav rail, which already gives the content its full height.
@visibleForTesting
const double kShellBarTabsHeight = 64;

/// Whether the swipe-away coach mark has been shown (#4106).
///
/// Once ever, like the #1690 swipe-between-tabs hint: a gesture needs
/// introducing exactly one time, and a hint that returns is an
/// annoyance rather than help.
@Riverpod(keepAlive: true)
class ShellSwipeCoachSeen extends _$ShellSwipeCoachSeen {
  /// The `settings`-box key the flag persists under.
  static const String storageKey = 'shell_swipe_coach_seen';

  @override
  bool build() {
    try {
      return ref.read(settingsStorageProvider).getSetting(storageKey) == true;
    } catch (e, st) {
      // No settings box yet: treat it as SEEN so a user can never be
      // shown a hint that cannot be remembered as dismissed.
      logFailure(e, st, where: 'ShellSwipeCoachSeen.build');
      return true;
    }
  }

  /// Mark it shown, for good.
  Future<void> markSeen() async {
    if (state) return;
    state = true;
    try {
      await ref.read(settingsStorageProvider).putSetting(storageKey, true);
    } catch (e, st) {
      logFailure(e, st, where: 'ShellSwipeCoachSeen.markSeen');
    }
  }
}
