// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../consumption/providers/wakelock_facade.dart';

/// #2677 / #2785 — the radar-screen pin: a wake lock + immersive system bars
/// so the closest-station readout stays readable on a dashboard mount. Mirrors
/// the trip-recording screen's pin. Extracted into a mixin so the search
/// screen stays under the file-length norm and the enable/disable system calls
/// live in one place.
///
/// State is ephemeral (not persisted); the persisted "always pin when the
/// radar starts" preference lives in `radarAutoPinProvider`.
mixin RadarScreenPinMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Whether the screen is currently pinned.
  bool pinned = false;

  /// Cached facade so [disposePin] can release the lock without touching `ref`
  /// after the widget has been deactivated.
  WakelockFacade? _cachedFacade;

  /// Toggle the pin (the AppBar pin button).
  Future<void> togglePin() async {
    final next = !pinned;
    if (mounted) setState(() => pinned = next);
    await (next ? _enable() : _disable());
  }

  /// Pin now if not already pinned — used by the auto-pin-on-radar-start path
  /// and the "always pin" toggle (#2785).
  Future<void> enablePinNow() async {
    if (pinned) return;
    if (mounted) setState(() => pinned = true);
    await _enable();
  }

  Future<void> _enable() async {
    final facade = ref.read(wakelockFacadeProvider);
    _cachedFacade = facade;
    await facade.enable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _disable() async {
    final facade = ref.read(wakelockFacadeProvider);
    _cachedFacade = facade;
    await facade.disable();
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  /// Best-effort release on dispose (must stay sync). Call from `dispose`.
  void disposePin() {
    if (!pinned) return;
    final facade = _cachedFacade;
    if (facade != null) unawaited(facade.disable());
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
  }
}
