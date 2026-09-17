// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../storage/hive_deferred_user_boxes.dart';

/// Holds a screen until the deferred user-data boxes have opened (#4318).
///
/// For a route whose providers read those boxes synchronously — the privacy
/// dashboard counts, exports and erases every store — and that a user could
/// in principle reach before the post-first-frame open has finished. On the
/// normal path the boxes are already open and [child] is built directly, on
/// the very first frame: no loading flash on every visit.
class DeferredUserBoxesGate extends StatelessWidget {
  const DeferredUserBoxesGate({super.key, required this.child});

  final Widget child;

  static bool get _ready =>
      HiveDeferredUserBoxes.names.every(HiveDeferredUserBoxes.isReadable);

  @override
  Widget build(BuildContext context) {
    if (_ready) return child;
    return FutureBuilder<void>(
      future: Future.wait(
          HiveDeferredUserBoxes.names.map(HiveDeferredUserBoxes.settled)),
      builder: (context, snapshot) =>
          snapshot.connectionState == ConnectionState.done
              ? child
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator())),
    );
  }
}
