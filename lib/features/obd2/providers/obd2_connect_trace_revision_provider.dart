// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/obd2_connect_trace_log.dart';

part 'obd2_connect_trace_revision_provider.g.dart';

/// A monotonically-increasing revision the OBD2 health screen watches so it
/// rebuilds when a NEW connect trace lands — including a LIVE reconnect /
/// first-connect failure the user never triggered from the screen (#2969).
///
/// The health screen read `Obd2CommDiagnostics.instance` / the trace log ONCE
/// per build with no listen, so a trace captured while the screen was open
/// stayed invisible until re-navigation. This provider bridges the static
/// [Obd2ConnectTraceLog] (deliberately Riverpod-free plumbing) to the widget
/// tree: the log calls a registered notify hook on every `endTrace`, the
/// provider bumps its int, and the screen's `ref.watch` rebuilds + re-reads the
/// (now larger) ring.
///
/// `keepAlive` so the revision survives the screen rebuilding on every bump.
@Riverpod(keepAlive: true)
class Obd2ConnectTraceRevision extends _$Obd2ConnectTraceRevision {
  @override
  int build() {
    // Register the static → provider notify bridge. Cleared on dispose so a
    // disposed provider never bumps (the keep-alive provider lives app-long, so
    // this is belt-and-braces for tests).
    Obd2ConnectTraceLog.onTraceAdded = _bump;
    ref.onDispose(() {
      if (Obd2ConnectTraceLog.onTraceAdded == _bump) {
        Obd2ConnectTraceLog.onTraceAdded = null;
      }
    });
    return 0;
  }

  void _bump() => state = state + 1;
}
