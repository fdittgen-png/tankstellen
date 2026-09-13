// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Wraps a screen so its FAB can get out of the way while the user is
/// scrolling (#4120).
///
/// A floating button floats: it covers whatever passes under it until
/// the list reaches its end, where the reserved clearance takes over.
/// That is ordinary and bounded — except when what passes under it is
/// INTERACTIVE. On the station-detail screen the rating stars are the
/// only tap targets in the FAB's path, and a user reaching for the fifth
/// star mid-scroll can press "Navigate" instead.
///
/// More clearance is not the answer — it would push the content further
/// from the thumb at rest to fix a transient — so the FAB yields
/// instead, collapsing to its icon while the list moves and expanding
/// again when it stops. The common Material behaviour, and it removes
/// the class of overlap rather than one instance of it.
///
/// The host has to sit OUTSIDE the `Scaffold`, because the FAB is a
/// sibling of the scroll view, not a descendant: scroll notifications
/// bubble up from the `Scrollable` through the Scaffold to here.
///
/// ```dart
/// ScrollAwareFabHost(
///   builder: (context, scrolling) => Scaffold(
///     floatingActionButton: MyFab(extended: !scrolling),
///     body: CustomScrollView(...),
///   ),
/// )
/// ```
class ScrollAwareFabHost extends StatefulWidget {
  const ScrollAwareFabHost({super.key, required this.builder});

  /// Builds the screen. `scrolling` is true while the user is dragging
  /// or a fling is still settling.
  final Widget Function(BuildContext context, bool scrolling) builder;

  @override
  State<ScrollAwareFabHost> createState() => _ScrollAwareFabHostState();
}

class _ScrollAwareFabHostState extends State<ScrollAwareFabHost> {
  bool _scrolling = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      // `UserScrollNotification` is the user's intent, not every pixel:
      // it fires on drag start and once more when the motion settles, so
      // this rebuilds twice per gesture rather than per frame.
      onNotification: (notification) {
        final scrolling =
            notification.direction != ScrollDirection.idle;
        if (scrolling != _scrolling) setState(() => _scrolling = scrolling);
        // Never absorbed: other listeners up the tree (and the shell's
        // own scroll-driven chrome) must still see it.
        return false;
      },
      child: widget.builder(context, _scrolling),
    );
  }
}
