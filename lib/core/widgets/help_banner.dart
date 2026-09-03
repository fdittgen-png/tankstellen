// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_keys.dart';
import '../storage/storage_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../core/error/guarded.dart';
import '../../core/logging/error_logger.dart';
import '../theme/app_radius.dart';
import 'help/help_tip_pager.dart';
import 'help/help_tips.dart';

export 'help/help_tips.dart' show HelpSurface;

/// A dismissible contextual help bubble — one tip, or a paged carousel.
///
/// ## The single-message contract (unchanged)
///
/// Constructed with a [message], it is the banner it has always been: an
/// icon, one sentence, a "Got it" button, and a flag persisted through
/// [SettingsStorage] so it never reappears. The four surfaces that used it
/// before #3938 (search criteria, alerts, consumption, vehicles) render
/// exactly as they did — no chevrons, no indicator, same footprint.
///
/// ## The paged bubble (#3938, Epic #3937)
///
/// Constructed with a [surface] instead, its tips come from [helpTipsFor]
/// and it grows the paging affordances: chevrons, horizontal swipe, an
/// `n/N` indicator, and a **remembered position** — a fresh visit opens on
/// the tip AFTER the one last shown, so each visit teaches something new.
/// That is what lets the epic delete permanent explanation from the
/// results chrome without losing the explanation.
///
/// Dismissal is per surface (the [storageKey] flag) and stays restorable
/// wherever those flags are reset from; the position lives in the paired
/// slot from [StorageKeys.helpBannerPositionKey].
class HelpBanner extends ConsumerStatefulWidget {
  /// Storage key used to persist the "shown" flag.
  final String storageKey;

  /// Icon displayed on the left.
  final IconData icon;

  /// The help message, for a one-tip surface. Ignored when [surface] is
  /// set; exactly one of the two must be given.
  final String? message;

  /// #3938 — the catalogued surface whose tips this bubble pages through.
  final HelpSurface? surface;

  const HelpBanner({
    super.key,
    required this.storageKey,
    required this.icon,
    this.message,
    this.surface,
  }) : assert(
         message != null || surface != null,
         'a HelpBanner needs either a message or a catalogued surface',
       );

  @override
  ConsumerState<HelpBanner> createState() => _HelpBannerState();
}

class _HelpBannerState extends ConsumerState<HelpBanner> {
  bool _visible = false;

  /// The tip on screen. Resolved once per visit from the stored position
  /// (see [_resolveInitialPage]) — a rebuild, or the position write
  /// landing, must never re-advance it.
  int _page = 0;
  bool _pageResolved = false;

  /// Last-shown index read back from storage, `null` when never visited or
  /// unreadable.
  int? _storedPage;

  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_checkIfShouldShow));
  }

  void _checkIfShouldShow() {
    try {
      final settings = ref.read(settingsStorageProvider);
      final shown = settings.getSetting(widget.storageKey);
      final stored = settings.getSetting(
        StorageKeys.helpBannerPositionKey(widget.storageKey),
      );
      if (!mounted) return;
      setState(() {
        _storedPage = stored is int ? stored : null;
        _visible = shown != true;
      });
    } catch (e, st) {
      // Widget tests without an initialized settings box — keep the
      // banner hidden rather than crashing.
      logFailure(
        e,
        st,
        where: 'HelpBanner: cannot read shown flag',
        layer: ErrorLayer.other,
      );
    }
  }

  /// First build of this visit: open on the tip after the stored one and
  /// remember it, so the NEXT visit moves on again. The write is deferred
  /// to a post-frame callback — a build must never trigger storage I/O.
  void _resolveInitialPage(int tipCount) {
    if (_pageResolved || tipCount == 0) return;
    _pageResolved = true;
    _page = initialTipIndex(_storedPage, tipCount);
    if (tipCount < 2) return;
    final opened = _page;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_persistPage(opened));
    });
  }

  Future<void> _persistPage(int page) async {
    try {
      await ref
          .read(settingsStorageProvider)
          .putSetting(
            StorageKeys.helpBannerPositionKey(widget.storageKey),
            page,
          );
    } catch (e, st) {
      // A lost position only costs the user one repeated tip.
      logFailure(
        e,
        st,
        where: 'HelpBanner: cannot persist tip position',
        layer: ErrorLayer.other,
      );
    }
  }

  void _goTo(int page) {
    setState(() => _page = page);
    unawaited(_persistPage(page));
  }

  Future<void> _dismiss() async {
    try {
      final settings = ref.read(settingsStorageProvider);
      await settings.putSetting(widget.storageKey, true);
    } catch (e, st) {
      logFailure(
        e,
        st,
        where: 'HelpBanner: cannot persist dismiss',
        layer: ErrorLayer.other,
      );
    }
    if (mounted) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final surface = widget.surface;
    final tips = surface != null
        ? helpTipsFor(l, surface)
        : <String>[widget.message ?? ''];
    _resolveInitialPage(tips.length);

    final onContainer = theme.colorScheme.onPrimaryContainer;
    final paged = tips.length > 1;
    final dismiss = TextButton(
      onPressed: _dismiss,
      child: Text(l.swipeTutorialDismiss),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.lg,
      ),
      child: Row(
        crossAxisAlignment: paged
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(widget.icon, color: onContainer, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: HelpTipPager(
              tips: tips,
              page: _page,
              onPageChanged: _goTo,
              keyPrefix: widget.storageKey,
              // Paged: the dismiss button joins the nav line, which hands
              // the tip back the ~70 dp the button used to take beside it
              // — at 320 dp that is the difference between a five-line
              // tip and a twelve-line one. A one-tip surface keeps the
              // trailing button, and with it its exact old footprint.
              navLeading: paged ? dismiss : null,
              foreground: onContainer,
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                color: onContainer,
              ),
            ),
          ),
          if (!paged) ...[const SizedBox(width: 8), dismiss],
        ],
      ),
    );
  }
}
