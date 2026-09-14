// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import 'service_result.dart';

/// How well a surface is currently able to do its job (#4134, Epic #4132).
///
/// The app depends on official price APIs, OSM/Overpass, a routing
/// service, GPS, Bluetooth, an OBD2 adapter, Supabase and local storage.
/// Any of them can be missing, slow or refusing, and each surface used to
/// decide for itself what that means and what to say — so the same
/// underlying condition read differently depending on where the user was
/// standing.
enum SurfaceState {
  /// Everything worked. **Say nothing**: silence is the healthy state,
  /// and a banner that is always there is a banner nobody reads.
  full,

  /// Working, with something missing or older than it should be. The
  /// user can still do what they came for.
  degraded,

  /// Serving what was already on the device. Not an error — a state.
  offline,
}

/// Map a service result onto the three states.
///
/// This is the decision `ServiceStatusBanner` used to make inline, named
/// so every other surface reaches the same verdict instead of inventing
/// its own.
SurfaceState surfaceStateOf(ServiceResult<dynamic> result) {
  if (result.isStale) return SurfaceState.offline;
  if (result.hadFallbacks) return SurfaceState.degraded;
  return SurfaceState.full;
}

/// How each state looks, so one condition looks the same everywhere.
///
/// **Neither degraded nor offline is an error.** Cached prices with no
/// network are the app doing its job under worse conditions, and painting
/// that in `errorContainer` — as the banner did — tells the user
/// something broke when nothing did. The error palette is reserved for
/// states that actually need a decision from them.
@immutable
class SurfaceStateStyle {
  const SurfaceStateStyle({required this.background, required this.icon});

  final Color background;
  final IconData icon;

  static SurfaceStateStyle? of(BuildContext context, SurfaceState state) {
    final scheme = Theme.of(context).colorScheme;
    return switch (state) {
      SurfaceState.full => null, // nothing to paint
      SurfaceState.degraded => SurfaceStateStyle(
          background: scheme.tertiaryContainer,
          icon: Icons.info_outline,
        ),
      SurfaceState.offline => SurfaceStateStyle(
          background: scheme.secondaryContainer,
          icon: Icons.cloud_off,
        ),
    };
  }
}
