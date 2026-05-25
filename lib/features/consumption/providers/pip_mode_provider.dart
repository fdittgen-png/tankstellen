// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/pip_controller.dart';

part 'pip_mode_provider.g.dart';

/// The single app-wide [PipController] (#1977).
///
/// Picture-in-Picture is Activity-bound and the `tankstellen/pip`
/// MethodChannel admits exactly one handler, so the controller must be
/// a singleton — every consumer reads this provider rather than
/// constructing its own (two controllers raced on the channel handler).
@Riverpod(keepAlive: true)
PipController pipController(Ref ref) {
  final controller = PipController();
  ref.onDispose(controller.dispose);
  return controller;
}

/// Whether the OS currently has the app shrunk into a Picture-in-
/// Picture tile (#1977).
///
/// App-wide so `TripRecordingBanner` — which wraps every screen via
/// `MaterialApp.builder` — can collapse the UI down to the compact
/// trip tile in PiP, regardless of which route was visible when PiP
/// fired. Before this, the compact tile only rendered when the user
/// happened to be on `/trip-recording`, so auto-PiP from a shell
/// branch shrank the whole shell — bottom nav bar and all — into the
/// tile.
@Riverpod(keepAlive: true)
class PipMode extends _$PipMode {
  @override
  bool build() {
    final sub = ref
        .watch(pipControllerProvider)
        .pipModeChanges
        .listen((inPip) => state = inPip);
    ref.onDispose(sub.cancel);
    return false;
  }
}
